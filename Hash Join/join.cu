#include<stdio.h>
#include<string>
#include<fstream>
#include<iostream>
#include <curand_kernel.h>
#include <vector>
#include <sstream>



#define p 334214459
#define TABLESIZE 100000
#define maxiterations 10
#define KEYEMPTY -1
#define NOTFOUND -100

__device__
unsigned long long  table[TABLESIZE];



__device__
unsigned long long make_entry(unsigned long key, unsigned long value){
  //printf("key : %d, value : %d",key , value);
  unsigned long long ans = (key<<32)+value;
  //printf ("ans : %d ", (int)ans>>32);
  printf("\n");
  return ans;
}

__device__ unsigned getkey(unsigned long long entry){
return (entry)>>32;
}

__device__ unsigned getvalue(unsigned long long entry){
  return (entry & 0xffffffff) ;
}

__device__
unsigned hash_function_1(unsigned key){
   int a1 = 5;
   int b1 = 2;
   return (((a1*key+b1)%p)%TABLESIZE);
}

__device__
unsigned hash_function_2(unsigned key){
   int a1 = 13;
   int b1 = 7;
   return (((a1*key+b1)%p)%TABLESIZE);
}



__global__
void join(int *Table_B,int *Table_C,int width_c,int width,int height){
  int index = blockIdx.x * blockDim.x +threadIdx.x;
  unsigned long primkey = Table_B[index*width+0];
   //printf("primkey : %lu \n",primkey);
  unsigned long value = Table_B[index*width+1];
  unsigned location_1 = hash_function_1(primkey);
  unsigned location_2 = hash_function_2(primkey);
  unsigned long long entry;
  if (getkey(entry = table[location_1])!= primkey)
    if (getkey(entry = table[location_2])!= primkey){
        entry = make_entry(0,NOTFOUND);
    }
 // printf("entry of primkey %lu:%llu \n",primkey,entry);
  //printf("key from hash table of primkey %lu: %d\n",primkey,getkey(entry));
  Table_C[index*width_c+0]=getkey(entry);
  Table_C[index*width_c+1]=getvalue(entry);
  //printf("key from hash table of primkey %lu: %d\n",primkey,getvalue(entry));
  Table_C[index*width_c+2] = value;
  //printf("value from hash table of primkey %lu: %d\n",primkey,value); 
  for(int l =0 ;l<3 ;l++){
    //printf("index : %d,Table: %d  ",index,Table_C[index*width_c+l]);
  }
  }

__global__
void hash(int *Table_A, int width, int height){
  
  int index = blockIdx.x * blockDim.x +threadIdx.x;
    unsigned long key = Table_A[index*width+0];
    unsigned long value = Table_A[index*width+1]; 
    unsigned long long entry = make_entry(key,value);
    //printf("entry: %d",entry);
    unsigned location = hash_function_1(key);
    unsigned k = key;
    for (int its = 0; its<maxiterations; its++){
    entry = atomicExch(&table[location], entry);
    key = getkey(entry);
    if (key == 0) {
      //printf("key: %lu table: %llu \n",k,table[location]);
      return;}
    unsigned location1 = hash_function_1(key);
    unsigned location2 = hash_function_2(key);
    if (location == location1)
     location = location2;
    else if (location == location2)
     location = location1;
    };
    printf("chain was too long");
    return ;
}



int main()
{

    int *Table_A;
    int *Table_B;
    int *Table_C;

    int width = 2;
    int width_c = 3;
    int height_a =  2500 ;//2500;
    int height_b =  1500000 ;//1500000;
    int num1=1;
    int num2 =101;
    int num3 = 201;
    int count =0;

     cudaMallocManaged(&Table_A, width * height_a * sizeof(unsigned long));
     cudaMallocManaged(&Table_B, width * height_b * sizeof(unsigned long));
     cudaMallocManaged(&Table_C, width_c * height_b * sizeof(unsigned long));
      std::fstream fin;
      fin.open("table_a.csv", std::ios::in);
      std::string line, word;
      int i=0;
      char delimiter;
      int temp[20];
      delimiter = ',';
      //std::string l = "hi how are you";
      while (getline(fin, line,'\n')){
        std::stringstream s(line);
        while (getline(s, word,','))
        {
          Table_A[i]=stoi(word);
          //std::cout<<"table_a: "<<Table_A[i]<<"\n";
          i++;
      }
    }
    fin.close();
    int k=0;
    fin.open("table_b.csv", std::ios::in);
    while (getline(fin, line,'\n')){
      std::stringstream s(line);
      while (getline(s, word,','))
      {
        Table_B[k]=stoi(word);
        //std::cout<<"table_b: "<<Table_B[k]<<"\n";
        k++;
      }
  }
  fin.close();


     hash<<<3,1024>>>(Table_A, width, height_a);
     cudaDeviceSynchronize();
     join<<<1465,1024>>>(Table_B,Table_C,width_c,width,height_b);
     cudaDeviceSynchronize();
    for(int i = 0;i<height_b;i++){
      for(int l =0 ;l<width_c ;l++){
      printf(" %d ",Table_C[i*width_c+l]);
    } 
    printf("\n");
  }
    printf("exit ");
}
