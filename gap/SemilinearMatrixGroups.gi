# Return a subgroup of <M>GL(s, q)</M> isomorphic to the subgroup of
# <M>\Gamma L(1, q ^ s)</M> consisting of all <C>GF(q)</C>-linear and 
# <C>GF(q ^ s)</C>-semilinear transformations of the vector space 
# <M>F'^1</M> over the field <C>F' := GF(q ^ s)</C>. 
# See <Ref Func="GammaLMeetSL"/> for further details.
#
# Construction as in Lemma 6.1 of [HR05]
# Note that in [HR05], it is falsely claimed that the group constructed is
# isomorphic to GammaL(1, q ^ s) when in fact it is only isomorphic to the
# subgroup of GammaL(1, q ^ s) consisting of all GF(q)-linear transformations.
BindGlobal("MatricesInducingGaloisGroupOfGFQToSOverGFQ",
function(s, q)
    local F, primitivePolynomial, A, x, xq, B, row, i;
    F := GF(q);
    # Let w be a primitive element of GF(q ^ s) over GF(q).
    # A acts on the standard basis in the same way as w acts by multiplication
    # on the GF(q)-basis {1, w, w ^ 2, ...} of GF(q ^ s). (Note that A is a
    # Singer cycle, i.e. has order q ^ s - 1.)
    primitivePolynomial := MinimalPolynomial(F, Z(q ^ s));
    A := TransposedMat(CompanionMat(primitivePolynomial));
    # B acts on the standard basis in the same way as the Frobenius acts on the
    # basis {1, w, w ^ 2, ...} of GF(q ^ s) over GF(q), where w is as above.
    x := IndeterminateOfUnivariateRationalFunction(primitivePolynomial);
    xq := PowerMod(x, q, primitivePolynomial);
    B := [];
    for i in [0 .. s - 1] do
        row := CoefficientsOfUnivariatePolynomial(PowerMod(xq,
                                                           i,
                                                           primitivePolynomial));
        row := Concatenation(row,
                             ListWithIdenticalEntries(s - Length(row),
                                                      Zero(F)));
        Add(B, row);
    od;
    return rec(A := A, B := B);
end);

# Return a block matrix where the block in place (i, j) is A ^ k if and only if
# the entry M[i, j] is omega ^ k (if M[i, j] = 0 then the corresponding block
# is zero as well).
# This is the function Theta(...) from [HR05].
BindGlobal("MapGammaLToGL",
function(M, A, omega)
    local result, i, j, exponent, dimensionOfA;

    if not NumberRows(A) = NumberColumns(A) then
        ErrorNoReturn("<A> must be a square matrix but <A> = ", A);
    fi;

    dimensionOfA := NumberRows(A);
    result := NullMat(NumberRows(M) * dimensionOfA, 
                      NumberColumns(M) * dimensionOfA, 
                      DefaultFieldOfMatrix(A));

    for i in [1..NumberRows(M)] do
        for j in [1..NumberColumns(M)] do
            if not IsZero(M[i, j]) then
                exponent := LogFFE(M[i, j], omega);
                result{[(i - 1) * dimensionOfA + 1..i * dimensionOfA]}
                      {[(j - 1) * dimensionOfA + 1..j * dimensionOfA]} 
                          := A ^ exponent;
            fi;
        od;
    od;

    return result;
end);

# Return the subgroup of <M>SL(n, q)</M> induced by the group of all 
# <C>GF(q)</C>-linear and <C>GF(q ^ s)</C>-semilinear
# transformations of the vector space <M>F'^m</M> over the field 
# <C>F' := GF(q ^ s)</C>, where <M>m := n / s</M>. (More precisely, there is
# an isomorphism of <M>F</M>-vector spaces, where <C>F := GF(q)</C>, between
# <M>F'</M> and <M>F ^ s</M>, which in turn induces an <M>F</M>-vector space
# isomorphism between <M>F'^m</M> and <M>F^n</M> and consequently an embedding
# of the subgroup of <M>\Gamma L(m, q ^ s)</M> consisting of all
# <C>GF(q)</C>-linear transformations of <M>F'^m</M> into <M>GL(n, q)</M>; 
# the intersection of the image of this embedding with <M>SL(n, q)</M> is a 
# subgroup of <M>SL(n, q)</M>.) Note that this means <A>s</A> must be a divisor 
# of <A>n</A>. We further demand that <A>s</A> be a prime number, i.e. <M>F'</M> 
# is a prime extension of <M>F</M>.
# Construction as in Proposition 6.3 of [HR05]
BindGlobal("GammaLMeetSL",
function(n, q, s)
    local F, As, Bs, Cs, Fs, m, gammaL1, zeta, AandB, C, D, DBlock, ZBlock, i,
    range, size;
    if n mod s <> 0 or not IsPrime(s) then
        ErrorNoReturn("<s> must be prime and a divisor of <n> but <s> = ", s,
                      " and <n> = ", n);
    fi;
    F := GF(q);
    gammaL1 := MatricesInducingGaloisGroupOfGFQToSOverGFQ(s, q);
    # Let w be a primitive element of GF(q ^ s) over GF(q). Since As is the
    # companion matrix of the minimal polynomial of w over GF(q), its
    # determinant is (-1) ^ s times the constant term of said minimal
    # polynomial. By Vieta, this constant term is (-1) ^ s * the product of
    # all Galois conjugates of w. Hence, det(As) = w ^ ((q ^ s - 1) / (q - 1)).
    As := gammaL1.A;
    # By Lemma 6.2 det(Bs) = (-1) ^ (s - 1).
    Bs := gammaL1.B;
    # det(Cs) = det(As) ^ (q - 1) = w ^ (q ^ s - 1) = 1.
    Cs := As ^ (q - 1);
    m := QuoInt(n, s);

    # Size according to Proposition 6.3 of [HR05]
    size := SizeSL(n / s, q ^ s) * (q ^ s - 1) / (q - 1) * s;

    if m = 1 then
        if n mod 2 = 1 then
            return MatrixGroupWithSize(F, [Bs, Cs], size);
        elif q mod 2 = 1 then
            Fs := (As ^ QuoInt(q - 1, 2)) * Bs;
            return MatrixGroupWithSize(F, [Cs, Fs], size);
        # n = s = 2 and q even
        else
            # In characteristic 2 we have det(Bs) = -1 = 1.
            return MatrixGroupWithSize(F, [Bs, Cs], size);
        fi;
    fi;

    zeta := PrimitiveElement(GF(q ^ s));
    AandB := List(GeneratorsOfGroup(SL(m, q ^ s)), g -> MapGammaLToGL(g, As, zeta));
    C := IdentityMat(n, F);
    C{[1..s]}{[1..s]} := Cs;
    D := IdentityMat(n, F);
    # The determinant of D might be -1. In these cases, adjust D.
    if s = 2 and IsOddInt(m) and IsOddInt(q) then
        ZBlock := As ^ QuoInt(q - 1, 2);
        DBlock := ZBlock * Bs;
    else
        DBlock := Bs;
    fi;
    for i in [0..m - 1] do
        range := [i * s + 1..(i + 1) * s];
        D{range}{range} := DBlock;
    od;

    return MatrixGroupWithSize(F, Concatenation(AandB, [C, D]), size);
end);

# Construction as in Proposition 6.6 of [HR05]
BindGlobal("GammaLMeetSU",
function(d, q, s)
    local F, As, Bs, Cs, Fs, m, gammaL1, Y, AandB, C, D, i,
    range, AsInGU, omega, generators, size;
    if d mod s <> 0 or not IsPrime(s) or not IsOddInt(s) then
        ErrorNoReturn("<s> must be an odd prime and a divisor of <d> but <s> = ", s,
                      " and <n> = ", d);
    fi;
    F := GF(q ^ 2);
    gammaL1 := MatricesInducingGaloisGroupOfGFQToSOverGFQ(s, q ^ 2);
    # Let w be a primitive element of GF(q ^ (2 * s)) over GF(q ^ 2). Since As is the
    # companion matrix of the minimal polynomial of w over GF(q ^ 2), its
    # determinant is (-1) ^ s times the constant term of said minimal
    # polynomial. By Vieta, this constant term is (-1) ^ s * the product of
    # all Galois conjugates of w. Hence, det(As) = w ^ ((q ^ (2 * s) - 1) / (q ^ 2 - 1)).
    As := gammaL1.A;
    # By Lemma 6.2 det(Bs) = (-1) ^ (s - 1). Bs has order s as it is the
    # Frobenius of the extension GF(q ^ 2) <= GF(q ^ (2 * s)).
    Bs := gammaL1.B;
    # Raise As to the (q ^ s - 1)-th power so that the result is in GammaU(1, q ^ s).
    # AsInGU now has order q ^ s + 1 (as As had order q ^ (2 * s) - 1).
    # det(AsInGU) = w ^ ((q ^ (2 * s) - 1) / (q + 1) * (q ^ s - 1) / (q - 1))
    AsInGU := As ^ (q ^ s - 1);
    # s is odd so (q ^ s - 1) / (q - 1) = 1 + q + ... + q ^ (s - 1) and q + 1
    # are coprime. Hence, we have to raise AsInGU to the (q + 1)-th power to
    # make the determinant 1. Cs has order (q ^ s + 1) / (q + 1).
    Cs := AsInGU ^ (q + 1);
    m := QuoInt(d, s);
    
    # Size according to Table 2.6 of [BHR13]
    size := SizeSU(d / s, q ^ s) * (q ^ s + 1) / (q + 1) * s;

    if m = 1 then
        # note that we require s to be odd
        generators := [Bs, Cs];
        # conjugate the result so that it preserves the standard unitary form
        return ConjugateToStandardForm(MatrixGroupWithSize(F, generators, size), "U");
    fi;

    omega := PrimitiveElement(GF(q ^ (2 * s)));
    # The following two matrices generate SU(m, q ^ s) as a subgroup of SU(d, q)
    AandB := List(GeneratorsOfGroup(SU(m, q ^ s)), g -> MapGammaLToGL(g, As, omega));
    # Note that GUMinusSU(m, q ^ s) ^ (q + 1) has determinant 1.
    C := MapGammaLToGL(GUMinusSU(m, q ^ s) ^ (q + 1), As, omega);
    # det(D) = 1
    D := IdentityMat(d, GF(q));
    for i in [0..m - 1] do
        range := [i * s + 1..(i + 1) * s];
        D{range}{range} := Bs;
    od;

    generators := Concatenation(AandB, [C, D]);
    # conjugate the result so that it preserves the standard unitary form 
    return ConjugateToStandardForm(MatrixGroupWithSize(F, generators, size), "U");
end);
