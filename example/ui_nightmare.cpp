struct {
    int value;
} a;

struct String{
    char* ptr = nullptr;
    String(){ptr = new char[1]; ptr[0]=0;}
    ~String(){delete ptr;}
    String(const String& s) {ptr = new char[1]; ptr[0] = s.ptr[0];}
};

template<typename T>
void tfunc(T t) {
    (void)t;
}

int main(int, char**){
    String var;
    String bor;
    auto b = [&,var](){return var.ptr[0]+bor.ptr[0];};
    tfunc(a);
    tfunc(b);
    return b();

}

