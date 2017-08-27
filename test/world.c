#include <stdio.h>
extern int intVal;
extern char strVal;
int main(void){
    printf("%d\n", intVal);
    intVal++;
    printf("%d\n", intVal);
    printf("%s\n", (char*)(&strVal));
    return 0;
}