int main(int argc, char* argv[])
{
   int i = 0;
   
   // testing forward branch pred (not taken - correct)
   if(0 > 1) {  // false
      i = 0xDEADBEEF;
   }

   // testing backward branch pred (taken - correct)
   // incorrect on last iteration (supposed to be not taken)
   int cnt = 0;
   for(i = 0; i < 2; i++) {
    cnt++;
   }
   return cnt;
}