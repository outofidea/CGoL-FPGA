#include "module_clock.hpp"

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

ModuleClock::~ModuleClock() = default;

auto ModuleClock::time_to_next_edge() const -> int
{
    return cur_clk_tick < half_clk_period ? half_clk_period - cur_clk_tick : clk_period - cur_clk_tick;
}

auto ModuleClock::value() const -> int
{
    return cur_clk_tick >= half_clk_period;
}

auto ModuleClock::advance(int ticks) -> int
{
    for (auto tick_count = 0; tick_count < ticks; ++tick_count)
    {
        tick();
    }

    return value();
}

auto ModuleClock::tick() -> int
{
    this->cur_clk_tick += 1;

    if (cur_clk_tick == clk_period)
    {
        cur_clk_tick = 0;
    }

    return value();
}