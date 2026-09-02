class ModuleClock
{
public:
    ModuleClock(int clk_period);
    ~ModuleClock();
    [[nodiscard]] auto time_to_next_edge() const -> int; //! CPP SHENANIGANS OMG
    auto tick() -> int;

private:
    int clk_period;
    int half_clk_period;
    int cur_clk_tick;
    int cur_clk_state;
};
