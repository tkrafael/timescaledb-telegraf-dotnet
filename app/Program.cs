using app;
using App.Metrics;
using App.Metrics.AspNetCore;
using App.Metrics.Filtering;
using App.Metrics.Formatters.InfluxDB;
using Microsoft.AspNetCore.Hosting;

IHost host = Host.CreateDefaultBuilder(args)
    .ConfigureMetricsWithDefaults(builder =>
    {
        var filter = new MetricsFilter().WhereType(new[] { MetricType.Timer, MetricType.Counter, MetricType.Apdex });
        var influxOptions = new MetricsInfluxDbLineProtocolOptions
        {
            MetricNameFormatter = (context, metricName) => $"{context}_{metricName}".ToLowerInvariant().Replace(".", "_")
        };

        builder.Report.OverHttp(options =>
        {
            options.HttpSettings.RequestUri = new Uri("http://localhost:8086/metrics");
            options.MetricsOutputFormatter = new MetricsInfluxDbLineProtocolOutputFormatter(influxOptions);
            options.Filter = filter;
            options.FlushInterval = TimeSpan.FromSeconds(60);
        });
    })
    .UseMetrics()
    .ConfigureServices(services =>
    {
        services.AddHostedService<Worker1>();
        services.AddHostedService<Worker2>();
        services.AddHostedService<Worker3>();
        services.AddHostedService<Worker4>();
    })

    .ConfigureLogging(a => a.SetMinimumLevel(LogLevel.Trace))
    .Build();

host.Run();