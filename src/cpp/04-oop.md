# Object-Oriented Programming

## The Core Idea

Object-Oriented Programming organizes code around **objects** — entities that bundle data (attributes) and behavior (functions) together. Instead of thinking "what do I do to this data?", you think "what does this object know and what can it do?"

**Analogy:** Think of a BankAccount. It has data (balance, account number, owner) and behaviors (deposit, withdraw, check balance). You don't operate on raw variables scattered around your code — you send messages to the BankAccount object: "deposit 500," "withdraw 200," "tell me your balance."

---

## Part 1 — Classes and Objects

### Defining a Class

```cpp
class BankAccount {
private:
    // data members (attributes)
    double balance;
    string owner;
    int accountNumber;

public:
    // constructor
    BankAccount(string ownerName, int accNum, double initialBalance = 0) {
        owner = ownerName;
        accountNumber = accNum;
        balance = initialBalance;
    }

    // member functions (methods)
    void deposit(double amount) {
        if (amount > 0)
            balance += amount;
    }

    bool withdraw(double amount) {
        if (amount > 0 && amount <= balance) {
            balance -= amount;
            return true;
        }
        return false;  // insufficient funds
    }

    double getBalance() const {  // const = doesn't modify the object
        return balance;
    }

    void display() const {
        cout << "Account: " << accountNumber
             << " | Owner: " << owner
             << " | Balance: $" << balance << "\n";
    }
};
```

### Creating and Using Objects

```cpp
int main() {
    BankAccount acc("Alice", 1001, 500.0);
    acc.deposit(200);
    acc.withdraw(100);
    cout << acc.getBalance();  // 600
    acc.display();

    // Dynamic allocation
    BankAccount* acc2 = new BankAccount("Bob", 1002, 1000.0);
    acc2->deposit(500);       // arrow operator for pointer access
    cout << acc2->getBalance();
    delete acc2;
}
```

### Access Modifiers

```cpp
class Example {
public:
    int pub;      // accessible from anywhere

protected:
    int prot;     // accessible from class and derived classes

private:
    int priv;     // accessible only within this class
};
```

**Encapsulation principle:** Make data `private`, provide `public` methods to access/modify it. This way, the class controls how its data is used — validation, side effects, invariants.

---

## Part 2 — Constructors and Destructors

### Constructors

Called automatically when an object is created.

```cpp
class Rectangle {
private:
    double width, height;

public:
    // Default constructor
    Rectangle() : width(1.0), height(1.0) {}

    // Parameterized constructor
    Rectangle(double w, double h) : width(w), height(h) {}

    // Copy constructor
    Rectangle(const Rectangle& other) : width(other.width), height(other.height) {}

    double area() const { return width * height; }
    double perimeter() const { return 2 * (width + height); }
};

Rectangle r1;             // default: 1×1
Rectangle r2(5.0, 3.0);  // 5×3
Rectangle r3 = r2;        // copy: 5×3
```

**Member initializer list** (use this instead of assignment in body):

```cpp
// Prefer this:
Rectangle(double w, double h) : width(w), height(h) {}

// Over this:
Rectangle(double w, double h) {
    width = w;   // assignment, not initialization
    height = h;
}
```

Initializer lists are more efficient (especially for const members, references, and class members without default constructors).

### Destructor

Called automatically when an object is destroyed. Used to release resources.

```cpp
class DynamicArray {
private:
    int* data;
    int size;

public:
    DynamicArray(int n) : size(n) {
        data = new int[n];  // allocate on heap
    }

    ~DynamicArray() {       // destructor — name is ~ClassName
        delete[] data;      // free heap memory
        cout << "DynamicArray destroyed\n";
    }

    int& operator[](int i) { return data[i]; }
    int getSize() const { return size; }
};

// Usage
void function() {
    DynamicArray arr(100);
    arr[0] = 42;
    // ... use arr ...
}  // arr goes out of scope — ~DynamicArray() called automatically
```

### Rule of Three / Five / Zero

**Rule of Three (C++03):** If you define any of these, define all three:
1. Destructor
2. Copy constructor
3. Copy assignment operator

**Rule of Five (C++11):** Also define move constructor and move assignment operator.

**Rule of Zero:** Design your class so you don't need any custom destructor, copy, or move operations — use smart pointers and standard containers instead.

```cpp
class MyClass {
    unique_ptr<int[]> data;  // smart pointer handles memory
    int size;

public:
    MyClass(int n) : data(make_unique<int[]>(n)), size(n) {}
    // No destructor, copy, or move needed — Rule of Zero
    // But: copy is deleted (can't copy unique_ptr)
    // Move works automatically
};
```

---

## Part 3 — Inheritance

### Basic Inheritance

A **derived class** inherits members from a **base class** and can add or override them.

**Analogy:** A SavingsAccount is a BankAccount — it has everything a BankAccount has, plus an interest rate and a method to apply interest.

```cpp
class Animal {
protected:
    string name;
    int age;

public:
    Animal(string n, int a) : name(n), age(a) {}

    virtual void speak() {    // virtual = can be overridden
        cout << name << " makes a sound\n";
    }

    virtual void describe() const {
        cout << "Animal: " << name << ", age " << age << "\n";
    }

    string getName() const { return name; }
};

class Dog : public Animal {   // Dog inherits from Animal
private:
    string breed;

public:
    Dog(string n, int a, string b) : Animal(n, a), breed(b) {}
    // Animal(n, a) calls the base constructor

    void speak() override {   // override = overriding virtual function
        cout << name << " barks: Woof!\n";
    }

    void fetch() {
        cout << name << " fetches the ball!\n";
    }

    void describe() const override {
        Animal::describe();   // call base version
        cout << "Breed: " << breed << "\n";
    }
};
```

### Types of Inheritance

```cpp
class Derived : public Base    {}  // public members stay public
class Derived : protected Base {}  // public members become protected
class Derived : private Base   {}  // all members become private
```

In practice, use `public` inheritance almost always.

### Calling Base Constructors

```cpp
class Shape {
protected:
    string color;
public:
    Shape(string c) : color(c) {}
};

class Circle : public Shape {
private:
    double radius;
public:
    Circle(double r, string c) : Shape(c), radius(r) {}
    //                            ^^^^^^^^^ must call base constructor
};
```

---

## Part 4 — Polymorphism

### Virtual Functions

The heart of runtime polymorphism — the right function is called based on the actual type of the object, not the declared type.

```cpp
class Shape {
public:
    virtual double area() const = 0;  // pure virtual — must override
    virtual void draw() const {
        cout << "Drawing a shape\n";
    }
    virtual ~Shape() {}  // ALWAYS make destructor virtual in base class
};

class Circle : public Shape {
    double radius;
public:
    Circle(double r) : radius(r) {}
    double area() const override { return 3.14159 * radius * radius; }
    void draw() const override { cout << "Drawing circle, r=" << radius << "\n"; }
};

class Rectangle : public Shape {
    double w, h;
public:
    Rectangle(double w, double h) : w(w), h(h) {}
    double area() const override { return w * h; }
    void draw() const override { cout << "Drawing rectangle " << w << "x" << h << "\n"; }
};
```

### Polymorphic Behavior

```cpp
void printArea(const Shape& s) {
    cout << "Area: " << s.area() << "\n";  // calls correct version!
}

int main() {
    Circle c(5.0);
    Rectangle r(4.0, 6.0);

    printArea(c);  // Area: 78.5398
    printArea(r);  // Area: 24

    // Polymorphism via pointer array
    vector<Shape*> shapes;
    shapes.push_back(new Circle(3.0));
    shapes.push_back(new Rectangle(2.0, 5.0));
    shapes.push_back(new Circle(1.0));

    for (Shape* s : shapes) {
        s->draw();     // calls correct draw() for each type
        cout << s->area() << "\n";
    }

    for (Shape* s : shapes) delete s;
}
```

### Abstract Classes

A class with at least one pure virtual function (`= 0`):

```cpp
class AbstractBase {
public:
    virtual void doSomething() = 0;  // pure virtual
    virtual ~AbstractBase() {}
};

// Can't instantiate:
// AbstractBase ab;  // compile error

// Can use as pointer/reference:
AbstractBase* ptr = new ConcreteClass();  // ok
```

**Interface pattern:** All members pure virtual — defines a contract without implementation.

---

## Part 5 — Operator Overloading

Give custom behavior to operators for your classes:

```cpp
class Vector2D {
public:
    double x, y;

    Vector2D(double x = 0, double y = 0) : x(x), y(y) {}

    // + operator
    Vector2D operator+(const Vector2D& other) const {
        return Vector2D(x + other.x, y + other.y);
    }

    // - operator
    Vector2D operator-(const Vector2D& other) const {
        return Vector2D(x - other.x, y - other.y);
    }

    // * scalar
    Vector2D operator*(double scalar) const {
        return Vector2D(x * scalar, y * scalar);
    }

    // == operator
    bool operator==(const Vector2D& other) const {
        return x == other.x && y == other.y;
    }

    // << for output (friend function)
    friend ostream& operator<<(ostream& os, const Vector2D& v) {
        os << "(" << v.x << ", " << v.y << ")";
        return os;
    }
};

int main() {
    Vector2D a(1, 2), b(3, 4);
    Vector2D c = a + b;      // (4, 6)
    Vector2D d = c * 2.0;    // (8, 12)
    cout << c;               // (4, 6)
    cout << (a == b);        // 0
}
```

---

## Practice Problems

**Classes:**

1. Design a `Student` class with name, rollNumber, and grades (vector of doubles). Include methods to compute average grade, add a grade, and print details.

2. Design a `Stack<int>` class using a dynamic array with push, pop, peek, and isEmpty methods.

**Inheritance:**

3. Create a class hierarchy: `Vehicle` → `Car`, `Truck`, `Motorcycle`. Each has a `describe()` method and the subclasses add specific attributes.

4. What is the output?
   ```cpp
   class A {
   public:
       virtual void f() { cout << "A"; }
   };
   class B : public A {
   public:
       void f() override { cout << "B"; }
   };
   A* ptr = new B();
   ptr->f();
   ```

**Operator Overloading:**

5. Create a `Fraction` class with numerator and denominator. Overload `+`, `-`, `*`, `/`, and `<<`.

6. Create a `Matrix` class that overloads `+` and `*` for 2×2 matrices.

---

## Answers to Selected Problems

**Problem 4:** Output is `B`.
The pointer type is `A*` but the actual object is `B`. Because `f()` is virtual, the runtime type (`B`) determines which function is called. This is runtime polymorphism.

**Problem 5 (Fraction):**
```cpp
class Fraction {
    int num, den;
    int gcd(int a, int b) { return b == 0 ? a : gcd(b, a%b); }
    void reduce() {
        int g = gcd(abs(num), abs(den));
        num /= g; den /= g;
        if (den < 0) { num = -num; den = -den; }
    }
public:
    Fraction(int n, int d) : num(n), den(d) { reduce(); }

    Fraction operator+(const Fraction& o) const {
        return Fraction(num*o.den + o.num*den, den*o.den);
    }
    Fraction operator*(const Fraction& o) const {
        return Fraction(num*o.num, den*o.den);
    }
    friend ostream& operator<<(ostream& os, const Fraction& f) {
        return os << f.num << "/" << f.den;
    }
};
```

---

## References

- Stroustrup, B. — *The C++ Programming Language* — Chapters 16-21
- Lippman et al. — *C++ Primer* — Chapters 13-15
- cppreference.com — [Classes](https://en.cppreference.com/w/cpp/language/classes)
- LearnCpp.com — [Chapter 13-17](https://www.learncpp.com)
