#pragma once

#include <format>
#include <iostream>
#include <string>

namespace console {

template <typename... Args>
void println(std::format_string<Args...> fmt, Args&&... args) {
    std::cout << std::format(fmt, std::forward<Args>(args)...) << std::endl;
}

inline void println(const std::string& str) {
    std::cout << str << std::endl;
}

inline void println() {
    std::cout << std::endl;
}

}
