
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
def read_file_bench(file1):
    with open(file1, 'r') as f1:
        lines1 = f1.readlines() 

 
    
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
    return   x  
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

def read_file(path_,f):
    file_path = os.path.join(path_,f)
    with open(file_path, "r") as file:
        data = json.load(file)
     
        x = {}
        for i in range(len(data)):
            x[data[i]['name'][:-4]] = data[i]['tools'][0]['result']
            
    return x
import os,json
if __name__ == "__main__":
    
    path_ = "/home/chenyidong/a/ADBench/omp_benchmark/ReverseMode/gmm"
    data = read_file(path_,"results_omp.json")
    i = 0
    scale = '1k'
    problem = 'gmm_d2_K5'
    key =  scale + '/' + problem

    t = np.array(data[key])
    
    benchmark = "/home/chenyidong/adb-results-1/Release/gmm/"+ scale + "/Manual/" + problem + "_J_Manual.txt"
    grad = read_file_bench(benchmark)
    g = np.array(grad)
    print(np.linalg.norm( t - g))
