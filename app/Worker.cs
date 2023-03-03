using App.Metrics;
using App.Metrics.Timer;

namespace app;

public class Worker1 : Worker
{
    public Worker1(IMetricsRoot metrics) : base(metrics, "worker1")
    {
    }
}

public class Worker2 : Worker
{
    public Worker2(IMetricsRoot metrics) : base(metrics, "worker2")
    {
    }
}

public class Worker3 : Worker
{
    public Worker3(IMetricsRoot metrics) : base(metrics, "worker3")
    {
    }
}

public class Worker4 : Worker
{
    public Worker4(IMetricsRoot metrics) : base(metrics, "worker4")
    {
    }
}


public abstract class Worker : BackgroundService
{
    private readonly IMetricsRoot metrics;
    private readonly string workerName;
    private static readonly TimerOptions executionCount = new()
    {
        Name = "executions",
        Context = "Worker.Executions",
        DurationUnit = TimeUnit.Milliseconds,
        ResetOnReporting = true,
        MeasurementUnit = Unit.Calls,
        RateUnit = TimeUnit.Minutes
    };

    public Worker(IMetricsRoot metrics, string workerName)
    {
        this.metrics = metrics;
        this.workerName = workerName;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var rnd = new Random();
        while (!stoppingToken.IsCancellationRequested)
        {
            var dimensions = new MetricTags(new[]{
                "execution_distribution_in_second",
                "worker"

            }, new[]{
                rnd.Next(0,2).ToString(),
                this.workerName

            });
            using var c = metrics.Measure.Timer.Time(executionCount, dimensions);
            await Task.Delay(100, stoppingToken);
        }
    }
}
