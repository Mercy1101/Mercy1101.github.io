---
layout: post
title:  "UML语法学习"
date:   2020-06-27 19:54:47 +0800
categories: UML
published:  true
tag: UML
typora-root-url: ..
---
## 类图
### 类之间的关系

类之间的关系通过下面的符号定义:

![类之间的关系](/resource/UML语法学习/Snipaste_2020-06-27_20-38-31.png)

```text
@startuml
Class01 <|-- Class02
Class03 *-- Class04
Class05 o-- Class06
Class07 .. Class08
Class09 -- Class10
@enduml
```
![class1](/resource/UML语法学习/class_uml_1.png)

```text
@startuml
Class11 <|.. Class12
Class13 --> Class14
Class15 ..> Class16
Class17 ..|> Class18
Class19 <--* Class20
@enduml
```
![class2](/resource/UML语法学习/class_uml_2.png)


```text
@startuml
Class21 #-- Class22
Class23 x-- Class24
Class25 }-- Class26
Class27 +-- Class28
Class29 ^-- Class30
@enduml
```
![class3](/resource/UML语法学习/class_uml_3.png)

### 关系上的标识
在关系之间使用标签来说明时, 使用: 后接标签文字。
对元素的说明，你可以在每一边使用"" 来说明.

```text
@startuml
Class01 "1" *-- "many" Class02 : contains
Class03 o-- Class04 : aggregation
Class05 --> "1" Class06
@enduml
```
![class4](/resource/UML语法学习/class_uml_4.png)

在标签的开始或结束位置添加< 或> 以表明是哪个对象作用到哪个对象上。

```text
@startuml
class Car
Driver - Car : drives >
Car *- Wheel : have 4 >
Car -- Person : < owns
@enduml
```
![class5](/resource/UML语法学习/class_uml_5.png)

### 添加方法
为了声明字段(对象属性）或者方法，你可以使用后接字段名或方法名。
系统检查是否有括号来判断是方法还是字段。

```text
@startuml
Object <|-- ArrayList
Object : equals()
ArrayList : Object[] elementData
ArrayList : size()
@enduml
```
![class6](/resource/UML语法学习/class_uml_6.png)

也可以使用{} 把字段或者方法括起来
注意，这种语法对于类型/名字的顺序是非常灵活的。
```text
@startuml
class Dummy {
String data
void methods()
}
class Flight {
flightNumber : Integer
departureTime : Date
}
@enduml
```
![class7](/resource/UML语法学习/class_uml_7.png)

你可以（显式地）使用{field} 和{method} 修饰符来覆盖解析器的对于字段和方法的默认行为
```text
@startuml
class Dummy {
{field} A field (despite parentheses)
{method} Some method
}
@enduml
```
![class8](/resource/UML语法学习/class_uml_8.png)

### 定义可访问性
一旦你定义了域或者方法，你可以定义相应条目的可访问性质。
![定义可访问性](/resource/UML语法学习/Snipaste_2020-06-27_20-55-15.png)

```text
@startuml
class Dummy {
-field1
#field2
~method1()
+method2()
}
@enduml
```
![class9](/resource/UML语法学习/class_uml_9.png)

你可以采用命令（skinparam classAttributeIconSize 0 ：)停用该特性
```text
@startuml
skinparam classAttributeIconSize 0
class Dummy {
-field1
#field2
~method1()
+method2()
}
@enduml
```
![class10](/resource/UML语法学习/class_uml_10.png)

### 抽象与静态
通过修饰符{static} 或者{abstract}，可以定义静态或者抽象的方法或者属性。
这些修饰符可以写在行的开始或者结束。也可以使用{classifier} 这个修饰符来代替{static}.

```text
@startuml
class Dummy {
{static} String id
{abstract} void methods()
}
@enduml
```
![class11](/resource/UML语法学习/class_uml_11.png)



## 对象图
### 对象的定义
使用关键字object 定义实例。
```text
@startuml
object firstObject
object "My Second Object" as o2
@enduml
```

如下图生成：

![object1](/resource/UML语法学习/object_uml_1.png)
### 对象之间的关系
对象之间的关系可以用如下符号定义：

![对象之间的关系](/resource/UML语法学习/Snipaste_2020-06-27_19-56-04.png)

也可以用.. 来代替-- 以使用点线。
知道了这些规则，就可以画下面的图：
可以用冒号给关系添加标签，标签内容紧跟在冒号之后。
用双引号在关系的两边添加基数。

```text
@startuml
object Object01
object Object02
object Object03
object Object04
object Object05
object Object06
object Object07
object Object08
Object01 <|-- Object02
Object03 *-- Object04
Object05 o-- "4" Object06
Object07 .. Object08 : some labels
@enduml
```
如下图生成：

![object2](/resource/UML语法学习/object_uml_2.png)

### 添加属性
用冒号加属性名的形式声明属性。
```text
@startuml
object user
user : name = "Dummy"
user : id = 123
@enduml
```

如下图生成：

![object3](/resource/UML语法学习/object_uml_3.png)

