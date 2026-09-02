#include "module_clock.h"

/*
?                _____________
?                |           |
?                |           |
?    ____________|           |____________
?    ^           ^           ^
?       half_clk
?                clk_period
?







*/

ModuleClock::ModuleClock(int clk_period)
{
    this->clk_period = clk_period;
    this->half_clk_period = clk_period / 2;
    this->cur_clk_tick = 0;
}

auto ModuleClock::time_to_next_edge() const -> int
{
    return half_clk_period - (cur_clk_tick - (cur_clk_state * half_clk_period));
}

auto ModuleClock::tick() -> int
{
    this->cur_clk_tick += 1;

    if (cur_clk_tick == half_clk_period)
    {
        cur_clk_state = 1;
    }

    if (cur_clk_tick == clk_period)
    {
        cur_clk_state = 0;
    }

    return cur_clk_state;
}