#include <iostream>
#include <string>
#include <sstream>
#include <format>


#include "console.hpp"
#define println console::println


// For ICU functionality
#include <unicode/uversion.h>
#include <unicode/unistr.h>
#include <unicode/ucnv.h>
#include <unicode/ubrk.h>
#include <unicode/translit.h>
#include <unicode/locid.h>
#include <unicode/numfmt.h>
#include <unicode/calendar.h>
#include <unicode/datefmt.h>
#include <unicode/brkiter.h>
#include <unicode/uclean.h>
#include <unicode/udata.h>
#include <unicode/ucal.h>
#include <unicode/uchar.h>
#include <unicode/ures.h>
#include <unicode/coll.h>
#include <unicode/resbund.h>

// Example 1: Unicode string operations
void runStringExample() {
    println();
    println("=== Running Unicode String Example ===");

    // Helper function to convert UnicodeString to std::string for output
    auto toString = [](const icu::UnicodeString& ustr) -> std::string {
        std::string result;
        ustr.toUTF8String(result);
        return result;
    };

    // Create a Unicode string with multi-language text
    icu::UnicodeString ustr("Hello, World! こんにちは 你好 مرحبا");
    println("Original string: {}", toString(ustr));

    // Get string properties
    println("Length: {} Unicode units", ustr.length());

    // Convert to uppercase
    icu::UnicodeString upper(ustr);
    upper.toUpper();
    println("Uppercase: {}", toString(upper));

    // Convert to lowercase
    icu::UnicodeString lower(ustr);
    lower.toLower();
    println("Lowercase: {}", toString(lower));
}

int main() {
    // Print ICU version
    println("ICU Version: {}", U_ICU_VERSION);

    // Run the string example
    runStringExample();

    println("ICU4C test completed successfully!");
    return 0;
}