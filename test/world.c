#include <stdio.h>
extern int* intVal;
int main(void){
    printf("%d", intVal);
    printf("%d", *intVal);
    (*intVal)++;
    printf("%d", *intVal);
    return 0;
}