
import numpy as np
def compare_files(file1, file2):
    with open(file1, 'r') as f1:
        lines1 = f1.readlines() 

    with open(file2, 'r') as f2:
        lines2 = f2.readlines()

    err = 0.0

    
    def check(lines1):
        x = []
        for i in lines1:
            for j in i.split('\n'):
                d = j.split(' ')
                for k in d:
                    if len(k):
                         
                        x.append(float(k))
        return np.array(x)
    x = check(lines1)
    y = check(lines2)
 
    #print(len(x))
 
 
     
    print(np.sum(x-y))
    return  

def compare_filesJ(file1, file2):
    with open(file1, 'r') as f1:
        lines1 = f1.readlines() 

    with open(file2, 'r') as f2:
        lines2 = f2.readlines()

    err = 0.0

    
    def check(lines1):
        x = []
        for i in lines1:
            for j in i.split('\n'):
                d = j.split(' ')
                for k in d:
                    if len(k):
                        k = k.split('\t')
                        for kk in k:

                            x.append(float(kk))
        return np.array(x)
    x = check(lines1)
    y = check(lines2)
    print(np.sum(x-y))
    return  
    
if __name__ == "__main__":
    #file1 = "/home/chenyidong/adb-results-1/Release/ba/Tapenade/ba1_n49_m7776_p31843_J_Tapenade.txt"
    file1 = "/home/chenyidong/adb-results-1/Release/gmm/1k/Manual/gmm_d10_K100_F_Manual.txt"
    file2 = "/home/chenyidong/output/gmm_omp/1k/gmm_d10_K100_F_Tapenade.txt"

    compare_files(file1, file2)

    file1 = "/home/chenyidong/adb-results-1/Release/gmm/1k/Manual/gmm_d10_K100_J_Manual.txt"
    file2 = "/home/chenyidong/output/gmm_omp/1k/gmm_d10_K100_J_Tapenade.txt" 
    compare_filesJ(file1,file2)