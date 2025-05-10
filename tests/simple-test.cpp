#include <iostream>
#include <string>
#include <sstream>
// #include <format>


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

// Example 2: Locale and formatting
void runLocaleExample() {
    std::cout << "\n=== Running Locale Example ===" << std::endl;
    
    // Helper function to convert UnicodeString to std::string for output
    auto toString = [](const icu::UnicodeString& ustr) -> std::string {
        std::string result;
        ustr.toUTF8String(result);
        return result;
    };
    
    // Create locales
    icu::Locale us("en_US");
    icu::Locale fr("fr_FR");
    icu::Locale jp("ja_JP");
    
    // Create UnicodeString objects to store display names
    icu::UnicodeString usName, frName, jpName;
    
    // Display locale information
    std::cout << "US Locale:       " << us.getName() << " (" << toString(us.getDisplayName(usName)) << ")" << std::endl;
    std::cout << "French Locale:   " << fr.getName() << " (" << toString(fr.getDisplayName(frName)) << ")" << std::endl;
    std::cout << "Japanese Locale: " << jp.getName() << " (" << toString(jp.getDisplayName(jpName)) << ")" << std::endl;
    
    // Number formatting
    UErrorCode status = U_ZERO_ERROR;
    std::unique_ptr<icu::NumberFormat> nf_us(icu::NumberFormat::createCurrencyInstance(us, status));
//     std::unique_ptr<icu::NumberFormat> nf_fr(icu::NumberFormat::createCurrencyInstance(fr, status));
//     std::unique_ptr<icu::NumberFormat> nf_jp(icu::NumberFormat::createCurrencyInstance(jp, status));
    
//     double amount = 1234567.89;
//     icu::UnicodeString result_us, result_fr, result_jp;
    
//     if (U_SUCCESS(status)) {
//         nf_us->format(amount, result_us);
//         nf_fr->format(amount, result_fr);
//         nf_jp->format(amount, result_jp);
        
//         std::cout << "Currency formatting:" << std::endl;
//         std::cout << "  US: " << toString(result_us) << std::endl;
//         std::cout << "  France: " << toString(result_fr) << std::endl;
//         std::cout << "  Japan: " << toString(result_jp) << std::endl;
//     }
}

int main() {
    // Print ICU version
    println("ICU Version: {}", U_ICU_VERSION);

    // Run the string example
    runStringExample();
    runLocaleExample();

    println("ICU4C test completed successfully!");
    return 0;
}