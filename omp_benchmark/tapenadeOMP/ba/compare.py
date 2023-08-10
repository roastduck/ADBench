
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
 
    print(len(x))
 
 
     
    print(np.sum(x-y))
    return  


if __name__ == "__main__":
    #file1 = "/home/chenyidong/adb-results-1/Release/ba/Tapenade/ba1_n49_m7776_p31843_J_Tapenade.txt"
    file1 = "/home/chenyidong/ba_output/ba1_n49_m7776_p31843_J_output.txt"
    file2 = "/home/chenyidong/adb-results-1/Release/ba/Manual/ba1_n49_m7776_p31843_J_Manual.txt"

    compare_files(file1, file2)

 
