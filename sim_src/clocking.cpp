#include "clocking.hpp"
#include <algorithm>

Clocking::Clocking(const vector<ModuleClock> module_clocks, VerilatedContext *ctx)
{
    this->module_clocks = module_clocks;
    this->ctx = ctx;
}

Clocking::~Clocking() = default;

void Clocking::step()
{
    auto min_clk_to_edge = std::min_element(module_clocks.begin(), module_clocks.end(), [](const auto &entry1, const auto &entry2) -> auto
                                            { return entry1.time_to_next_edge() < entry2.time_to_next_edge(); }); //! I HATE CPP

    auto ticks_to_next_edge = min_clk_to_edge->time_to_next_edge();
    for (auto &module_clock : module_clocks)
    {
        module_clock.advance(ticks_to_next_edge);
    }
    ctx->timeInc(ticks_to_next_edge);
}

auto Clocking::value(size_t index) const -> int
{
    return module_clocks.at(index).value();
}
