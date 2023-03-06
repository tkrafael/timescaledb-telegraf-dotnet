-- cria tabela de controle
CREATE TABLE public.tables_historify (
	time_index_name varchar(100) NOT NULL, -- nome do índice, sem o schema
	table_name varchar(100) NOT NULL, -- nome da tabela, sem o schema
	schema_name varchar(100) NOT NULL, -- nome do schema
	move_chunks_older_than_days int4 NOT NULL DEFAULT 10, -- periodo em dias para considerar que o chunk deve ser movido
	enabled bool NOT NULL DEFAULT true, -- se o job está habilitado ou não
	move_to_tablespace varchar(30) NOT NULL, -- tablespace de destino
	move_from_tablespace varchar(30) NULL -- tablespace de origin, se não estiver preenchido, usa o tablespace default
);

CREATE UNIQUE INDEX tables_historify_table_name_idx ON public.tables_historify USING btree (table_name, schema_name, move_from_tablespace, move_to_tablespace);

-- cria dois tablespaces, sendo um lento, mas mais rápido que o tablespace original
-- e o outro tablespace, muito lento, para fins de histórico
create tablespace slow LOCATION '/data/slow';
create tablespace veryslow LOCATION '/data/veryslow';

-- essa procedure tem como objetivo mover o chunk de um tablespace a outro com base em três parâmetros
-- 1. tempo de vida do chunk
-- 2. onde o chunk está guardado atualmente
-- 3. para qual tablespace o chunk será movido
-- Ex:
-- Um determinado chunk nasce no tablespace default (null), criamos uma regra para após 7 dias mover do tablespace default (null) para o tablespace slow
-- criamos também uma regra para mover chunks com 14 dias de vida, que estão no tablespace slow para o tablespace veryslow
-- O tempo de vida é contado a partir da criação do chunk e não a partir da última movimentação
CREATE OR REPLACE PROCEDURE public.move_history(IN jobid integer, IN config jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare 
	c1 cursor for select 
		format('%I.%I', c.chunk_schema, c.chunk_name) chunk,
		c.hypertable_schema,
		c.hypertable_name table_name, th.move_to_tablespace tablespace_name, th.time_index_name 
	from timescaledb_information.chunks c 
	inner join public.tables_historify th on th.table_name = c.hypertable_name and c.hypertable_schema = th.schema_name  
	where range_end < now() - interval '1d' * th.move_chunks_older_than_days
	--and hypertable_name = 'smartcampaign_triggers' 
	and th.enabled
	and coalesce(chunk_tablespace, 'default') = coalesce(th.move_from_tablespace, 'default')
    -- o limit serve para duas funções:
    -- 1. limitar o tamanho da transação
    -- 2. evitar alto consumo no banco para a movimentação de dados.
    -- essa procedure deve rodar a cada 5 min, olhando tudo que está vencido, e movendo, limitando-se a 10 registros por vez. 
    -- Esse valor eventualmente será configurado no job e recebido através do parametro config, da procedure
	order by range_end asc limit 10;
	test_cur RECORD;
BEGIN
	open c1;
	loop
		fetch from c1 into test_cur;
		exit when not FOUND;	
	RAISE NOTICE 'start % for %', test_cur.chunk, test_cur.table_name;	
	perform move_chunk(
		chunk =>test_cur.chunk,
		destination_tablespace => test_cur.tablespace_name,
		index_destination_tablespace => test_cur.tablespace_name,
		reorder_index => format('%I.%I', test_cur.hypertable_schema, test_cur.time_index_name),
		verbose => true
		);
		RAISE NOTICE 'Value: % for %', test_cur.chunk, test_cur.table_name;
	end loop;	
	close c1;
end;
$procedure$
;
