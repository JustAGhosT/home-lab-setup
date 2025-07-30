#!/usr/bin/env python3
"""
Test script to verify the ReDoS fix for CLOSED_ATX_HEADING_PATTERN
"""

import re
import time

# Old vulnerable pattern (for comparison)
OLD_PATTERN = re.compile(r"^#{1,6}\s+[^\s](?:[^\s]*(?:\s+[^\s]+)*)?[^\s]\s+#{1,6}\s*$")

# New safe pattern
NEW_PATTERN = re.compile(r"^#{1,6}\s+.*?\s+#{1,6}\s*$")

def test_patterns():
    """Test both patterns with valid and malicious inputs"""
    
    # Valid closed ATX headings
    valid_headings = [
        "# This is a heading #",
        "## This is a level 2 heading ##",
        "### Multi word heading ###",
        "###### Maximum level heading ######",
        "# Single word #",
        "## Two words ##"
    ]
    
    # Malicious input that could cause ReDoS
    malicious_input = "# " + "a " * 1000 + "b" * 1000 + " #"
    
    print("Testing valid headings...")
    for heading in valid_headings:
        old_match = OLD_PATTERN.match(heading)
        new_match = NEW_PATTERN.match(heading)
        print(f"'{heading}' - Old: {bool(old_match)}, New: {bool(new_match)}")
    
    print("\nTesting performance with malicious input...")
    
    # Test old pattern (should be slow)
    start_time = time.time()
    try:
        old_result = OLD_PATTERN.match(malicious_input)
        old_time = time.time() - start_time
        print(f"Old pattern: {old_time:.4f}s, Match: {bool(old_result)}")
    except KeyboardInterrupt:
        print("Old pattern: TIMEOUT (ReDoS vulnerability confirmed)")
    
    # Test new pattern (should be fast)
    start_time = time.time()
    new_result = NEW_PATTERN.match(malicious_input)
    new_time = time.time() - start_time
    print(f"New pattern: {new_time:.4f}s, Match: {bool(new_result)}")

if __name__ == "__main__":
    test_patterns()
