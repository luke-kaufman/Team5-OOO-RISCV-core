int main() {
    register int a = 0, b = 1, c = 0, i = 0, n = 10;
    for (i = 0; i < n; i++) {
        c = a + b;
        a = b;
        b = c;
    }
}