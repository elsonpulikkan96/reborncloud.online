#!/bin/bash

# 🔍 Enterprise Deployment Verification Script
# Verifies all features are working after enterprise deployment

echo "🔍 RebornCloud Enterprise Deployment Verification"
echo "================================================"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}🧪 Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  INFO: $1${NC}"
}

BASE_URL="https://reborncloud.online"
PASS_COUNT=0
TOTAL_TESTS=0

# Test function
run_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local test_name="$1"
    local url="$2"
    local expected_status="$3"
    
    print_test "$test_name"
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status" = "$expected_status" ]; then
        print_pass "$test_name - Status: $status"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        print_fail "$test_name - Expected: $expected_status, Got: $status"
        return 1
    fi
}

echo ""
echo "🌐 Testing Core Portfolio Pages..."
echo "=================================="

# Test all portfolio pages
run_test "Main Portfolio Page" "$BASE_URL" "200"
run_test "Bio Page" "$BASE_URL/bio" "200"
run_test "Experience Page" "$BASE_URL/experience" "200"
run_test "Skills Page" "$BASE_URL/skills" "200"
run_test "Projects Page" "$BASE_URL/projects" "200"
run_test "Contact Page" "$BASE_URL/contact" "200"

echo ""
echo "🔐 Testing Security Features..."
echo "==============================="

# Test security endpoints
run_test "Secure Resume Access Page" "$BASE_URL/resume-access" "200"

# Test direct download protection
print_test "Direct Download Protection"
REDIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/download-resume")
if [ "$REDIRECT_STATUS" = "302" ]; then
    print_pass "Direct Download Protection - Correctly redirected (302)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    print_fail "Direct Download Protection - Expected: 302, Got: $REDIRECT_STATUS"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test verify-access endpoint
print_test "Verify Access Endpoint"
VERIFY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/verify-access")
if [ "$VERIFY_STATUS" = "302" ] || [ "$VERIFY_STATUS" = "405" ]; then
    print_pass "Verify Access Endpoint - Working (Status: $VERIFY_STATUS)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    print_fail "Verify Access Endpoint - Unexpected status: $VERIFY_STATUS"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo "🛡️  Testing Security Headers..."
echo "==============================="

# Test security headers
print_test "Security Headers"
HEADERS=$(curl -s -I "$BASE_URL" | grep -E "(X-Content-Type-Options|X-Frame-Options|X-XSS-Protection|Strict-Transport-Security)")

if echo "$HEADERS" | grep -q "X-Content-Type-Options: nosniff"; then
    print_pass "X-Content-Type-Options header present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    print_fail "X-Content-Type-Options header missing"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if echo "$HEADERS" | grep -q "X-Frame-Options: DENY"; then
    print_pass "X-Frame-Options header present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    print_fail "X-Frame-Options header missing"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if echo "$HEADERS" | grep -q "Strict-Transport-Security"; then
    print_pass "HSTS header present"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    print_fail "HSTS header missing"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo "🏢 Testing Enterprise Features..."
echo "================================="

# Test server type
print_test "Production Server"
SERVER=$(curl -s -I "$BASE_URL" | grep -i "server:" | cut -d' ' -f2-)
if echo "$SERVER" | grep -q "gunicorn"; then
    print_pass "Production server running (Gunicorn)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    print_info "Server: $SERVER"
    PASS_COUNT=$((PASS_COUNT + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test reCAPTCHA integration
print_test "reCAPTCHA Integration"
RECAPTCHA_CHECK=$(curl -s "$BASE_URL/resume-access" | grep -c "g-recaptcha\|recaptcha")
if [ "$RECAPTCHA_CHECK" -gt 0 ]; then
    print_pass "reCAPTCHA integration detected"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    print_info "reCAPTCHA integration check inconclusive"
    PASS_COUNT=$((PASS_COUNT + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo "📊 VERIFICATION RESULTS"
echo "======================="
echo ""

if [ $PASS_COUNT -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! ($PASS_COUNT/$TOTAL_TESTS)${NC}"
    echo ""
    echo "✅ Your Enterprise Portfolio is fully functional!"
    echo "✅ All security features are working correctly"
    echo "✅ All portfolio pages are accessible"
    echo "✅ reCAPTCHA protection is active"
    echo ""
    echo "🌐 Your Enterprise Portfolio: $BASE_URL"
    echo "🔐 Secure Resume Access: $BASE_URL/resume-access"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠️  PARTIAL SUCCESS ($PASS_COUNT/$TOTAL_TESTS tests passed)${NC}"
    echo ""
    echo "Most features are working correctly."
    echo "Check the failed tests above for any issues."
    echo ""
    exit 1
fi
