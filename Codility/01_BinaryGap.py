
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

def OddOccurencesInArray(a):

    unmatched = set()
    for e in a:
        try:
            unmatched.remove(e)
        except KeyError:
            unmatched.add(e)

    return unmatched.pop()

OddOccurencesInArray([9, 3, 9, 3, 9, 7, 9])

def FrogJmp(x, y, d):
    quot, rem = divmod(y - x, d)

    return quot + 1 if rem != 0 else quot

FrogJmp(10, 85, 30)