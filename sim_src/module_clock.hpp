#pragma once

class ModuleClock
{
public:
    ModuleClock(int clk_period);
    ~ModuleClock();
    [[nodiscard]] auto time_to_next_edge() const -> int; //! CPP SHENANIGANS OMG
    [[nodiscard]] auto value() const -> int;
    auto advance(int ticks) -> int;
    auto tick() -> int;

private:
    int clk_period;
    int half_clk_period;
    int cur_clk_tick;
    int cur_clk_state;
};
