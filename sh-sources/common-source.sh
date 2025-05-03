# SOURCE ME - DO NOT RUN


if [[ "$BUILD_LOG" == "" ]]; then
  echo "BUILD_LOG is not set!"
  exit 1
fi


# == PRITNING FUNCTIONS ==

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


print() {
  echo "$@" | tee -a "$BUILD_LOG"
}

println() {
  echo "" | tee -a "$BUILD_LOG"
}

print_section() {
  echo -e "\n${YELLOW}=== $1 ===${NC}\n"
  echo ""           >> "$BUILD_LOG"
  echo "=== $1 ===" >> "$BUILD_LOG"
  echo ""           >> "$BUILD_LOG"
}

print_status() {
  echo -e "${BLUE}$1${NC}\n"
  echo "$1" >> "$BUILD_LOG"
  echo ""   >> "$BUILD_LOG"
}
exit_with_error() {
  echo -e "${RED}ERROR: $1${NC}"
  echo "ERROR: $1" >> "$BUILD_LOG"
  exit 1
}

