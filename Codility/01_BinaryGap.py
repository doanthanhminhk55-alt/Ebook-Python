
def BinaryGap(N):
    binary_string = str(bin(N))[2:]

    gap = max_gap = 0

    for string in binary_string:
        if string =="0":
            gap +=1
        else:
            max_gap = max(gap, max_gap)
            gap = 0

    return max_gap

BinaryGap(9)

def CyclicRotation(A, K):

    if not len(A):
        return A
    
    mod_k = (len(A) + K) % len(A)

    if mod_k == 0:
        return A
    
    head = A[:-mod_k]
    tail = A[len(A) - mod_k:]
    return tail + head

CyclicRotation([3,4,5,6,7], 2)
