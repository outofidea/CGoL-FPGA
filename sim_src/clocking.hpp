#include "module_clock.hpp"
#include "verilated.h"
#include <cstddef>
#include <vector>
#pragma once

using namespace std;
class Clocking
{
public:
    Clocking(const vector<ModuleClock> module_clocks, VerilatedContext* ctx);
    ~Clocking();
    void step();
    [[nodiscard]] auto value(size_t index) const -> int;
private:
    vector<ModuleClock> module_clocks;
    VerilatedContext* ctx;
};
