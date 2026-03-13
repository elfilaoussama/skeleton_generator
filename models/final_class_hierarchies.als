module final_class_hierarchies

-- ============================================================================
-- 1. GIVEN SETS AND FREE TYPES
-- ============================================================================
sig TYPE {}
sig SIGNATURE {}
sig EXPRESSION {}
sig NAME {}

abstract sig PropertyID {}
sig AttributeID extends PropertyID {}
sig MethodID extends PropertyID {}
sig ClassID {}
sig ObjectID {}

enum Visibility { Pub, Priv, Prot, Pkg }
enum YesNo { Yes, No }
enum Scope { Instance, Static }
enum ClassKind { ConcreteClass, Interface }

-- ============================================================================
-- 2. ATTRIBUTE AND METHOD SIGNATURES
-- ============================================================================
sig Method {
    mid       : one MethodID,
    mname     : one NAME,
    msig      : one SIGNATURE,
    mvis      : one Visibility,
    mscope    : one Scope,
    rtype     : one TYPE,
    isAbstract: one YesNo
}

sig Attribute {
    aid       : one AttributeID,
    aname     : one NAME,
    atype     : one TYPE,
    avis      : one Visibility,
    ascope    : one Scope
}

sig MethodBody {
    vars  : set AttributeID,
    calls : set MethodID,
    exprs : set EXPRESSION
}

-- ============================================================================
-- 3. CLASS STRUCTURE
-- ============================================================================
sig Class {
    cid            : one ClassID,
    kind           : one ClassKind,
    parents        : set Class,
    attributes     : set Attribute,
    methods        : set Method,
    iattributes    : set Attribute,
    imethods       : set Method,
    isAbstract     : one YesNo,
    implementation : MethodID -> lone MethodBody
}

sig Object {}

one sig World {
    instances : ClassID -> set Object
}

-- ============================================================================
-- 4. BASIC WELL-FORMEDNESS
-- ============================================================================
fact UniqueClassIds {
    all disj c1, c2 : Class | c1.cid != c2.cid
}

fact UniqueMethodIds {
    all disj m1, m2 : Method | m1.mid != m2.mid
}

fact UniqueAttributeIds {
    all disj a1, a2 : Attribute | a1.aid != a2.aid
}

-- ============================================================================
-- 5. RELATIONS: PARENTS, ANCESTORS, OFFSPRING
-- ============================================================================
fact NoCycles {
    no c : Class | c in c.^parents
}

fun children [c : Class] : set Class { c.~parents }
fun ancestors [c : Class] : set Class { c.^parents }
fun offspring [c : Class] : set Class { c.^(~parents) }

-- ============================================================================
-- 6. INHERITANCE LOGIC (WITH DIAMOND PROBLEM FIX)
-- ============================================================================
fact InheritedMethods {
    all c : Class |
        c.imethods = { m : Method |
            some anc : ancestors[c] |
                m in anc.methods and m.mvis != Priv
        }
}

fact InheritedAttributes {
    all c : Class |
        c.iattributes = { a : Attribute |
            some anc : ancestors[c] |
                a in anc.attributes and a.avis != Priv
        }
}

fact NoMethodNameConflictInInherited {
    all c : Class | all disj m1, m2 : c.imethods | m1.mname != m2.mname
}

fact DisjointLocalInherited {
    all c : Class | no c.methods & c.imethods
    all c : Class | no c.attributes & c.iattributes
}

-- ============================================================================
-- 7. ABSTRACTION & INTERFACE RULES
-- ============================================================================
fact Abstraction {
    all c : Class | (
        (some m : c.methods | m.isAbstract = Yes or m.mid not in (c.implementation).MethodBody)
        or
        (some m : c.imethods |
            (m.mid not in (c.implementation).MethodBody) and
            (no anc : ancestors[c] | m.mid in (anc.implementation).MethodBody)
        )
    ) implies c.isAbstract = Yes
      else    c.isAbstract = No
}

fact AbstractMethodNoBody {
    all c : Class, m : c.methods | m.isAbstract = Yes implies m.mid not in (c.implementation).MethodBody
}

fact InterfaceRules {
    all c : Class | c.kind = Interface implies {
        c.isAbstract = Yes
        no c.attributes
        no c.implementation
        all m : c.methods | m.isAbstract = Yes and m.mvis = Pub and m.mscope = Instance
    }
}

fact InheritanceKinds {
    all c : Class | c.kind = ConcreteClass implies lone p : c.parents | p.kind = ConcreteClass
    all c : Class | c.kind = Interface implies all p : c.parents | p.kind = Interface
}

-- ============================================================================
-- 8. OWNERSHIP AND SCOPE CONSTRAINTS
-- ============================================================================
fact ExclusiveOwnership {
    all m : Method | one c : Class | m in c.methods
    all a : Attribute | one c : Class | a in c.attributes
}

fact StaticMethodsCannotBeAbstract {
    all m : Method | m.mscope = Static implies m.isAbstract = No
}

-- ============================================================================
-- 9. EXTENSIONAL/IMPLEMENTATION CONSTRAINTS
-- ============================================================================
fact AbstractClassNoInstances {
    all c : Class | c.isAbstract = Yes implies no World.instances[c.cid]
}

fact DisjointClassesRule {
    all disj c1, c2 : Class |
        (no World.instances[c1.cid] & World.instances[c2.cid]) implies
            no offspring[c1] & offspring[c2]
}

fact NoPhantomImplementations {
    all c : Class | all midval : MethodID |
        (some mb : MethodBody | midval -> mb in c.implementation) implies
        (some m : c.methods | m.mid = midval) or (some m : c.imethods | m.mid = midval)
}

pred overrides [c : Class, anc : Class, m : Method] {
    anc in ancestors[c]
    m in anc.methods
    m.mvis != Priv
    some m2 : c.methods | m2.mname = m.mname
}

fact OverridingImpliesImplementation {
    all c : Class, anc : Class, m : Method |
        overrides[c, anc, m] implies
            (some m2 : c.methods |
                m2.mname = m.mname and
                (m2.isAbstract = Yes or m2.mid in (c.implementation).MethodBody))
}

-- ============================================================================
-- 10. METRICS HELPERS (Coupling)
-- ============================================================================
pred useMethods [c1, c2 : Class] {
    some (MethodID.(c1.implementation)).calls &
         (c2.methods.mid + c2.imethods.mid)
}

pred useVariables [c1, c2 : Class] {
    some (MethodID.(c1.implementation)).vars &
         (c2.attributes.aid + c2.iattributes.aid)
}

pred coupled [c1, c2 : Class] {
    useMethods[c1, c2] or useVariables[c1, c2] or
    useMethods[c2, c1] or useVariables[c2, c1]
}
