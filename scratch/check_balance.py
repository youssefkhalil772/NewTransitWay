import sys

def check_balance(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    mapping = {')': '(', '}': '{', ']': '['}
    
    for i, char in enumerate(content):
        if char in '({[':
            stack.append((char, i))
        elif char in ')}]':
            if not stack:
                print(f"Extra closing {char} at index {i}")
                return
            top, pos = stack.pop()
            if top != mapping[char]:
                print(f"Mismatched {char} at index {i}, expected {mapping[char]} but got {top}")
                return
    
    if stack:
        for char, pos in stack:
            print(f"Unclosed {char} at index {pos}")
    else:
        print("Everything is balanced!")

if __name__ == "__main__":
    check_balance(sys.argv[1])
