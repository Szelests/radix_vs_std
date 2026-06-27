#include "../include/timer_utils.hpp"

namespace utils {

    Timer::Timer() {
        reset();
    }

    void Timer::reset() {
        start_timepoint = std::chrono::high_resolution_clock::now();
    }

    long long Timer::getElapsedMicroseconds() const {
        auto end_timepoint = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_timepoint - start_timepoint);
        return duration.count();
    }

    long long Timer::getElapsedNanoseconds() const {
        auto end_timepoint = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end_timepoint - start_timepoint);
        return duration.count();
    }

} // namespace utils