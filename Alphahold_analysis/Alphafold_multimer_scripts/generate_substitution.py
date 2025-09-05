# generate_substitutions.py

def generate_substitutions(sequence):
    amino_acids = "ACDEFGHIKLMNPQRSTVWY"  # All 20 standard amino acids
    substitutions = []

    for i in range(len(sequence)):
        for aa in amino_acids:
            if aa != sequence[i]:  # Ensuring we don't include the original amino acid
                substituted = sequence[:i] + aa + sequence[i+1:]
                substitutions.append(substituted)

    return substitutions

# Given sequence
sequence = "RGVPAGPDPLHH"
substitutions = generate_substitutions(sequence)

# Print each substitution
for sub in substitutions:
    print(sub)
