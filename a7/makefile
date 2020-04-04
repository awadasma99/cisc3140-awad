# begin makefile 

JFLAGS = -g
JC = javac
JVM = java 
# FILE =


.SUFFIXES: .java .class


.java.class:
	$(JC) $(JFLAGS) $*.java

CLASSES = \
	Hello.java 

MAIN = Hello


default: classes
	$(JVM) Hello


classes: $(CLASSES:.java=.class)


run: $(MAIN).class
	$(JVM) run 


clean:
	$(RM) *.class
