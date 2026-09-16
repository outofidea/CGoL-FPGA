#include <Vtop_sim.h>
#include <verilated_fst_c.h>
#include "module_clock.hpp"
#include "clocking.hpp"
#include <memory>

enum
{
    CALC_CLK_PERIOD_TICKS = 10,
    DISP_CLK_PERIOD_TICKS = 99,
};

auto main(int argc, char const *argv[]) -> int
{
    using namespace std;

    shared_ptr<VerilatedContext> ctx(new VerilatedContext);

    ctx->commandArgs(argc, argv);
    ctx->traceEverOn(true);

    auto *top = new Vtop_sim(ctx.get());
    auto trace = std::make_unique<VerilatedFstC>();
    top->trace(trace.get(), 99);
    trace->open("top.fst");

    ModuleClock calc_clk_gen(CALC_CLK_PERIOD_TICKS);
    ModuleClock disp_clk_gen(DISP_CLK_PERIOD_TICKS);
    Clocking clocks({calc_clk_gen, disp_clk_gen}, ctx.get());

    top->rst_but_n = 0;
    top->pll_lock = 0;
    top->sw_5 = 0;
    top->sw_4 = 0;

    for (auto step = 0; step < 1000000 && !ctx->gotFinish(); ++step)
    {

        if (ctx->time() >= 300)
        {
            top->pll_lock = 1;
        }
        
        if (ctx->time() >= 400)
        {   
            
            top->rst_but_n = 1;
        }

        if (ctx->time() >= 700)
        {
            top->sw_4 = 1;
        }
        

        top->calc_clk = clocks.value(0);
        top->disp_clk = clocks.value(1);
        top->eval();
        trace->dump(ctx->time());
        clocks.step();
    }

    top->final();
    trace->close();
    delete top;
    return 0;
}
