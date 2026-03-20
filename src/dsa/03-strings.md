# Strings

## Strings as Character Arrays

A string is a sequence of characters. Internally, it's just an array of chars — everything you learned about arrays applies here, plus specialized string algorithms.

**Real-world analogy:** DNA is a string over alphabet {A, T, G, C}. Bioinformatics is essentially string algorithms applied to DNA — pattern matching, alignment, comparing sequences. The same algorithms used to search for a virus mutation are used in text editors to find and replace.

---

## Part 1 — String Fundamentals in C++

```cpp
#include <string>

string s = "Hello, World!";

// Size
s.length();     // 13
s.size();       // 13 — identical

// Access
s[0];           // 'H'
s.front();      // 'H'
s.back();       // '!'

// Substring
s.substr(7, 5); // "World" — start at 7, length 5
s.substr(7);    // "World!" — from 7 to end

// Find
s.find("World");          // 7 — first occurrence
s.rfind("l");             // 10 — last occurrence
s.find("xyz");            // string::npos — not found

// Modify
s += " Bye";              // concatenate
s.replace(7, 5, "C++");  // "Hello, C++!"
s.insert(5, ",");
s.erase(5, 1);

// Comparison — lexicographic
"abc" < "abd";   // true
"abc" == "abc";  // true

// Iteration
for (char c : s) cout << c;
for (int i = 0; i < s.size(); i++) cout << s[i];

// Convert
string num = to_string(42);       // "42"
int n = stoi("42");               // 42
double d = stod("3.14");          // 3.14

// Case conversion
transform(s.begin(), s.end(), s.begin(), ::toupper);
transform(s.begin(), s.end(), s.begin(), ::tolower);
```

---

## Part 2 — String Algorithms

### Palindrome Check

A string that reads the same forward and backward.

```cpp
bool isPalindrome(string s) {
    int left = 0, right = s.size() - 1;
    while (left < right) {
        if (s[left] != s[right]) return false;
        left++; right--;
    }
    return true;
}
// "racecar" → true, "hello" → false
// Time: O(n), Space: O(1)

// Ignore non-alphanumeric, case-insensitive
bool isPalindromeAdvanced(string s) {
    int left = 0, right = s.size() - 1;
    while (left < right) {
        while (left < right && !isalnum(s[left])) left++;
        while (left < right && !isalnum(s[right])) right--;
        if (tolower(s[left]) != tolower(s[right])) return false;
        left++; right--;
    }
    return true;
}
// "A man, a plan, a canal: Panama" → true
```

### Anagram Check

Two strings are anagrams if one is a rearrangement of the other.

```cpp
// Sort approach — O(n log n)
bool isAnagram(string a, string b) {
    sort(a.begin(), a.end());
    sort(b.begin(), b.end());
    return a == b;
}

// Frequency count — O(n)
bool isAnagram(string a, string b) {
    if (a.size() != b.size()) return false;
    int freq[26] = {};
    for (char c : a) freq[c - 'a']++;
    for (char c : b) {
        freq[c - 'a']--;
        if (freq[c - 'a'] < 0) return false;
    }
    return true;
}
// "listen" and "silent" → true
```

### Reverse Words in a String

```cpp
string reverseWords(string s) {
    // 1. reverse entire string
    reverse(s.begin(), s.end());

    // 2. reverse each word
    int start = 0;
    for (int i = 0; i <= s.size(); i++) {
        if (i == s.size() || s[i] == ' ') {
            reverse(s.begin() + start, s.begin() + i);
            start = i + 1;
        }
    }
    return s;
}
// "Hello World" → "World Hello"
```

---

## Part 3 — Pattern Matching

### Naive String Search

Check every position in text for the pattern.

```cpp
vector<int> naiveSearch(string text, string pattern) {
    vector<int> result;
    int n = text.size(), m = pattern.size();
    for (int i = 0; i <= n - m; i++) {
        bool match = true;
        for (int j = 0; j < m; j++) {
            if (text[i+j] != pattern[j]) { match = false; break; }
        }
        if (match) result.push_back(i);
    }
    return result;
}
// Time: O(nm)
```

### KMP — Knuth-Morris-Pratt

Avoids re-examining characters by using information from previous matches. The key insight: when a mismatch happens, we already know part of the text — use that to skip comparisons.

**Analogy:** You're searching for "ABAB" in text. You've matched "ABA" and then mismatch. Instead of going back to the start, you realize "AB" at the end of your match is also the start of the pattern — so you continue from there.

**LPS Array (Longest Proper Prefix which is also Suffix):**

```cpp
vector<int> buildLPS(string pattern) {
    int m = pattern.size();
    vector<int> lps(m, 0);
    int len = 0, i = 1;

    while (i < m) {
        if (pattern[i] == pattern[len]) {
            lps[i++] = ++len;
        } else if (len > 0) {
            len = lps[len-1];
        } else {
            lps[i++] = 0;
        }
    }
    return lps;
}
// "AABAAB": lps = {0,1,0,1,2,3}
```

```cpp
vector<int> KMP(string text, string pattern) {
    vector<int> result;
    int n = text.size(), m = pattern.size();
    vector<int> lps = buildLPS(pattern);

    int i = 0, j = 0;
    while (i < n) {
        if (text[i] == pattern[j]) { i++; j++; }
        if (j == m) {
            result.push_back(i - j);
            j = lps[j-1];
        } else if (i < n && text[i] != pattern[j]) {
            if (j > 0) j = lps[j-1];
            else i++;
        }
    }
    return result;
}
// Time: O(n + m), Space: O(m)
```

### Rabin-Karp — Rolling Hash

Use hashing to quickly find candidate positions, then verify.

```cpp
vector<int> RabinKarp(string text, string pattern) {
    vector<int> result;
    int n = text.size(), m = pattern.size();
    long long base = 31, mod = 1e9 + 7;
    long long power = 1;

    for (int i = 0; i < m - 1; i++) power = power * base % mod;

    long long patHash = 0, windowHash = 0;
    for (int i = 0; i < m; i++) {
        patHash = (patHash * base + (pattern[i] - 'a' + 1)) % mod;
        windowHash = (windowHash * base + (text[i] - 'a' + 1)) % mod;
    }

    for (int i = 0; i <= n - m; i++) {
        if (windowHash == patHash)
            if (text.substr(i, m) == pattern)  // verify
                result.push_back(i);

        if (i < n - m) {
            windowHash = (windowHash - (text[i] - 'a' + 1) * power % mod + mod) % mod;
            windowHash = (windowHash * base + (text[i+m] - 'a' + 1)) % mod;
        }
    }
    return result;
}
// Time: O(n + m) average, O(nm) worst (many hash collisions)
```

---

## Part 4 — Important String Problems

### Longest Common Subsequence (LCS)

Find the longest subsequence present in both strings (characters don't need to be contiguous).

```cpp
int LCS(string a, string b) {
    int m = a.size(), n = b.size();
    vector<vector<int>> dp(m+1, vector<int>(n+1, 0));

    for (int i = 1; i <= m; i++)
        for (int j = 1; j <= n; j++)
            if (a[i-1] == b[j-1])
                dp[i][j] = dp[i-1][j-1] + 1;
            else
                dp[i][j] = max(dp[i-1][j], dp[i][j-1]);

    return dp[m][n];
}
// "ABCBDAB" and "BDCAB" → 4 ("BCAB" or "BDAB")
// Time: O(mn), Space: O(mn)
```

### Longest Common Substring

Find the longest contiguous substring present in both.

```cpp
int longestCommonSubstring(string a, string b) {
    int m = a.size(), n = b.size(), maxLen = 0;
    vector<vector<int>> dp(m+1, vector<int>(n+1, 0));

    for (int i = 1; i <= m; i++)
        for (int j = 1; j <= n; j++)
            if (a[i-1] == b[j-1]) {
                dp[i][j] = dp[i-1][j-1] + 1;
                maxLen = max(maxLen, dp[i][j]);
            }

    return maxLen;
}
```

### Longest Palindromic Substring

**Expand Around Center approach:**

```cpp
string longestPalindrome(string s) {
    int start = 0, maxLen = 1;

    auto expand = [&](int left, int right) {
        while (left >= 0 && right < s.size() && s[left] == s[right]) {
            if (right - left + 1 > maxLen) {
                maxLen = right - left + 1;
                start = left;
            }
            left--; right++;
        }
    };

    for (int i = 0; i < s.size(); i++) {
        expand(i, i);     // odd length palindromes
        expand(i, i+1);   // even length palindromes
    }

    return s.substr(start, maxLen);
}
// "babad" → "bab" or "aba"
// Time: O(n²), Space: O(1)
```

### String Compression

```cpp
string compress(string s) {
    string result = "";
    int i = 0;
    while (i < s.size()) {
        char c = s[i];
        int count = 0;
        while (i < s.size() && s[i] == c) { i++; count++; }
        result += c;
        if (count > 1) result += to_string(count);
    }
    return result.size() < s.size() ? result : s;
}
// "aabcccccaaa" → "a2bc5a3"
// "abc" → "abc" (not compressed — longer)
```

---

## Practice Problems

**Easy:**
1. Count the number of vowels and consonants in a string.
2. Check if a string is a rotation of another ("waterbottle" is rotation of "erbottlewat").
3. Find the first non-repeating character in a string.

**Medium:**
4. Given a string, find the length of the longest substring without repeating characters.
5. Given a string of brackets, check if they are balanced.
6. Find all permutations of a string.

**Hard:**
7. Find the minimum window substring containing all characters of a pattern.
8. Find the longest substring with at most k distinct characters.

---

## Answers to Selected Problems

**Problem 2 (Rotation check):**
```cpp
bool isRotation(string a, string b) {
    if (a.size() != b.size()) return false;
    return (a + a).find(b) != string::npos;
    // If b is a rotation of a, it appears in a+a
}
```

**Problem 3 (First non-repeating):**
```cpp
char firstUnique(string s) {
    int freq[26] = {};
    for (char c : s) freq[c-'a']++;
    for (char c : s)
        if (freq[c-'a'] == 1) return c;
    return '\0';
}
```

**Problem 4 (Longest substring without repeating):**
```cpp
int lengthOfLongestSubstring(string s) {
    unordered_map<char, int> lastSeen;
    int left = 0, maxLen = 0;
    for (int right = 0; right < s.size(); right++) {
        if (lastSeen.count(s[right]) && lastSeen[s[right]] >= left)
            left = lastSeen[s[right]] + 1;
        lastSeen[s[right]] = right;
        maxLen = max(maxLen, right - left + 1);
    }
    return maxLen;
}
// "abcabcbb" → 3 ("abc")
// Sliding window + hash map
```

**Problem 7 (Minimum window substring):**
```cpp
string minWindow(string s, string t) {
    unordered_map<char, int> need, have;
    for (char c : t) need[c]++;
    int formed = 0, required = need.size();
    int left = 0, minLen = INT_MAX, start = 0;

    for (int right = 0; right < s.size(); right++) {
        char c = s[right];
        have[c]++;
        if (need.count(c) && have[c] == need[c]) formed++;

        while (formed == required) {
            if (right - left + 1 < minLen) {
                minLen = right - left + 1;
                start = left;
            }
            have[s[left]]--;
            if (need.count(s[left]) && have[s[left]] < need[s[left]])
                formed--;
            left++;
        }
    }
    return minLen == INT_MAX ? "" : s.substr(start, minLen);
}
// s="ADOBECODEBANC", t="ABC" → "BANC"
```

---

## References

- Cormen et al. — *Introduction to Algorithms* — Chapter 32 (String Matching)
- Sedgewick & Wayne — *Algorithms* — Chapter 5 (Strings)
- KMP Visualization — [visualgo.net/en/suffixarray](https://visualgo.net/en/suffixarray)
- LeetCode — [String problems](https://leetcode.com/tag/string/)
