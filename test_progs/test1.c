int hello();
int main(int argc, char* argv[])
{
   register int x = 15; // register variable
   x = x + 19;
   x = x - 4;
   x = x ^ 0x80000000;  // flip sign bit
   x = x & 0x7FFFFFFF;  // 
   return x;
}

// int hello()
// {
//    int x = 15;
//    if(x+19 == 34) {
//         return 42;
//     } else {
//         return 1;   
//    }
// }