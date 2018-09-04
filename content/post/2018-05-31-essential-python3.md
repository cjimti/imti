---
layout:     post
title:      "Essential Python 3"
subtitle:   "Programming in Python"
date:       2018-05-31
author:     "Craig Johnston"
URL:        "essential-python3/"
image:      "/img/post/watchgears.jpg"
twitter_image: "/img/post/watchgears_876_438.jpg"
tags:
- Python
series:
- Python
---

This article is a quick tour of basic [Python] 3 syntax, components and structure. I intend to balance a cheat sheet format with hello world style boilerplate. If you are already a software developer and need a quick refresh on [Python] then I hope you benefit from my notes below.

I am a professional software developer for a software development company, and for that reason, I work with a lot of languages, expert in some, and ok in others.  I context switch often, and sometimes months in between languages. I  often find myself just needing a quick overview to prime the pump so to say, and rather than keep my notes to myself I thought I would clean them up a bit and publish for anyone needing a quick tour, starting with [Python] and more languages as time and interest permits.

Each of the following code blocks are executable.

{{< toc >}}

### Script Execution

Scripts should execute with the environment available python3.

```python
#!/usr/bin/env python3
```

### Script Boilerplate

See [python-boilerplate.com](https://www.python-boilerplate.com/py3+executable) for more boilerplate examples. However, this is a good start for most Python 3 scripts. Read more on [PEP 257 -- Docstring Conventions](https://www.python.org/dev/peps/pep-0257/).

```python
#!/usr/bin/env python3
"""
Docstring
"""
__author__ = "Craig Johnston"
__version__ = "0.0.1"
__license__ = "MIT"


def main():
    """
        Main Function
    """
    print("Python 3")


if __name__ == '__main__': main()
"""
 Ensures main() only gets executed if the script is
 executed directly and not as an include.
"""

```

### Types

Read the official documentation on [Python3 Built-in Types](https://docs.python.org/3/library/stdtypes.html).

```python
#!/usr/bin/env python3
"""
Types
"""
__author__ = "Craig Johnston"
__version__ = "0.0.1"
__license__ = "MIT"


def main():
    """
        Main Function
    """
    print("Some Python 3 Types")

    # list of various type
    some_types = [
        ['a','list'],
        ('a','tuple'),
        dict(a='im a dictionary', b='type of map'),
        {"a": "another dictionary", "b": "json flavor"},
        1,
        1.1,
        1 + 1.1,
        'a string',
        "another" ' string',
    ]

    for i, v in enumerate(some_types):
        print(f'Idx: {i:>03} is a {type(v)} with value: {v}')


if __name__ == '__main__': main()
"""
 Ensures main() only gets executed if the script is
 executed directly and not as an include.
"""

```

### Conditional & Control Flow

Read the official documentation for Python3 [Control Flow](https://docs.python.org/3/tutorial/controlflow.html).

```python
#!/usr/bin/env python3
"""
Conditionals
"""
__author__ = "Craig Johnston"
__version__ = "0.0.1"
__license__ = "MIT"


def main():
    """
        The main function is demonstrating conditionals.
    """
    print("Python 3: Conditionals")

    x = True
    y = x

    if x:
        print(f'x has the value: {repr(x)} and the id: {id(x)}')  # eg 4361511296
        print(f'x has the value: {repr(y)} and the id: {id(y)}')  # eg 4361511296

    if x == y:
        print('Simple comparison')
    elif not y:
        print('Not my thing really')
    else:
        print('We should probably refactor...')

    y = False  # no longer the same as y
    if not y:
        print(f'y has the value: {repr(y)} and the id: {id(y)}')  # eg 4532404640

    if (x and not y) or (not x and y):
        print('XOR')

    a = [1,2,3]
    if 2 in a:
        print(f'found 2 in {a}')

    salad = "spinach with cucumber and carrots"
    if 'cucumber' in salad:
        print(f'found a cucumber in {repr(salad)}')

    if 'bug' not in salad:
        print(f'good. no bug in {repr(salad)}')


if __name__ == '__main__': main()
"""
 Ensures main() only gets executed if the script is
 executed directly and not as an include.
"""

```

### Loops

Check out a few [loop examples at learnpython.org](https://www.learnpython.org/en/Loops).

```python
#!/usr/bin/env python3
"""
Some example Loops
"""
__author__ = "Craig Johnston"
__version__ = "0.0.1"
__license__ = "MIT"


def main():
    """
        Loops
    """
    print("Python 3: Loops")

    words = example_while_loops(words=["one", "two", "three", "four"])
    print(f'words: {words}')

    example_for_loops(words)

    # for i in words:
    #     print(i)


def example_for_loops(words):
    """
    Example for loops
    :param words:
    :return set:
    """
    
    for w in words:
        print(f'Word {w} in words has a lengh of {len(w)}.')

    for i in range(len(words)):
        print(f'Word at index {i} is {words[i]}')

    return words


def example_while_loops(words):
    """
    Example while loops
    :param words:
    :return set:
    """
    n = 0
    while n < len(words):
        print(f'{words[n]} is index {n} in {words}')
        n = n + 1

    print("Pop out two.")
    n = 0
    while True:
        if n > len(words) - 1:
            break
        if words[n] == 'two':
            words.pop(n)
            continue
        n = n + 1

    return words


if __name__ == '__main__': main()
"""
 Ensures main() only gets executed if the script is
 executed directly and not as an include.
"""
```

### Classes

Check out [class and object examples at learnpython.org](http://learnpython.org/en/Classes_and_Objects).

```python
#!/usr/bin/env python3
"""
Example Classes
"""
__author__ = "Craig Johnston"
__version__ = "0.0.1"
__license__ = "MIT"


class Animal:
    """
    Animal

    __init__ is the constructor
    """
    def __init__(self, type, sound):
        """
        Constructor documentation.

        The underscore is a convention for private
        :param type: string, type of animal
        :param sound: string, sound the animal makes
        """
        self._type = type
        self._sound = sound

    def type(self, t=None):
        """
        Animal.type

        Example getter / setter. If t is defined then we
        set. We always return.
        :param t: string, type of animal
        :return: string, type of animal
        """
        if t:
            self._type = t
        return self._type

    def sound(self, s=None):
        """
        Animal.sound

        Example getter/setter. If s is defined, then we set. We always return.
        :param s: string, sound the animal makes
        :return: string, sound the animal makes
        """
        if s:
            self._sound = s
        return self._sound

    def __str__(self):
        """
        String representation.
        :return: string representation of an animal
        """
        return f'The {self.type()} goes {self.sound()}.'


class Snake(Animal):
    """
    Snake is a Subclass of Animal
    """

    def __init__(self):
        super().__init__('Snake', 'sssss')

    @staticmethod
    def eat(*animals):
        for a in animals:
            if isinstance(a, Snake):
                print(f'The Snake eats itself!')
                return
            if isinstance(a, Animal):
                print(f'The Snake eats the {a.type()} as it goes {a.sound()}.')



def main():
    """
        Example Classes
    """
    print("Python 3")

    animals = [
        Animal("Owl", "whoo"),
        Animal("Pig", "oink"),
        Animal("Dog", "woof"),
        Animal("Cat", "meow"),
        Snake(),
        "This is a rock."
    ]

    for a in animals:
        print(a)

    # find the snake
    snake = [a for a in animals if isinstance(a, Snake)]

    # free the owl
    owl = animals.pop(0)
    print(f'Freeing the {owl.type()} as it goes {owl.sound()}')

    # feed the snake
    if len(snake):
        snake[0].eat(*animals)


if __name__ == '__main__': main()
"""
 Ensures main() only gets executed if the script is
 executed directly and not as an include.
"""
```

### Python Books on Amazon

- [Python Crash Course: A Hands-On, Project-Based Introduction to Programming](https://amzn.to/2LYUpYb)
- [Learning Python, 5th Edition](https://amzn.to/2JvTno8)
- [Automate the Boring Stuff with Python: Practical Programming for Total Beginners](https://amzn.to/2sGvSht)

[Python]: https://www.python.org/