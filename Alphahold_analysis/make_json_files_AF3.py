# generate_CLV1_CLV3_mutants.py
import json, copy, os

WT_NAME = "SlCLV1_SlCLV3_WT"
WT_RECEPTOR = ("MVAPGTSALLDWNNNTKNYPFSHCSFSGITCNNNSHVISINITNVPLFGTIPPEIGLLQNLENLTIFGDNLTGTLPLEMSQLSSIKHVNLSYNNFSGPFPREILLGLIKLESFDIYNNNFTGELPIEVVKLKNLETLHLGGNYFHGEIPEVYSHIVSLKWLGLEGNSLTGKIPKSLALLPNLEELRLGYYNSYEGGIPSEFGNISTLKLLDLGNCNLDGEVPPSLGNLKKLHSLFLQVNRLTGHIPSELSGLESLMSFDLSFNQLTGEIPESFVKLQKLTLINLFRNNLHGPIPSFIGDLPNLEVLQIWGNNFTLELPENLGRNGRLLFLDISINHFTGRIPPDLCKGGKLKTLILMENYFFGPIPEQLGECKSLTRIRVRKNYLNGTIPAGFFKLPALDMLELDNNYFTGELPTEINANNLTKLVLSNNWITGNIPPSLGNLKNLVTLSLDVNRLSGEIPQEIASLNKLVTINLSGNNLTGEIPSSIALCSELTLVDLSRNQLVGEVPKEITKLNSLNALNLSRNQLSGAIPGEV")
WT_PEPTIDE = "RGVPAGPDPLHH"  # positions: 1..12
PTM_POSITIONS = {4, 7}         # hydroxyproline (HYP) at these positions in WT
AA20 = "ACDEFGHIKLMNPQRSTVWY"

template = [{
    "name": WT_NAME,
    "modelSeeds": ["194892698"],
    "sequences": [
        {
            "proteinChain": {
                "sequence": WT_RECEPTOR,
                "count": 1,
                "useStructureTemplate": False
            }
        },
        {
            "proteinChain": {
                "sequence": WT_PEPTIDE,
                "modifications": [{"ptmType": "CCD_HYP", "ptmPosition": 4},
                                  {"ptmType": "CCD_HYP", "ptmPosition": 7}],
                "count": 1,
                "useStructureTemplate": True
            }
        }
    ],
    "dialect": "alphafoldserver",
    "version": 1
}]

os.makedirs("mutants", exist_ok=True)

for i, wt_aa in enumerate(WT_PEPTIDE, start=1):
    for mut_aa in AA20:
        if mut_aa == wt_aa:
            continue
        mut_code = f"{wt_aa}{i}{mut_aa}"   # e.g., R1A
        mut = copy.deepcopy(template)

        # mutate 12-mer
        seq = list(WT_PEPTIDE)
        seq[i-1] = mut_aa
        new_seq = "".join(seq)
        mut[0]["name"] = f"SlCLV1_SlCLV3_{mut_code}"
        mut[0]["sequences"][1]["proteinChain"]["sequence"] = new_seq

        # keep HYP only if the residue at that position is still Proline
        new_mods = []
        for pos in PTM_POSITIONS:
            if new_seq[pos-1] == "P":
                new_mods.append({"ptmType": "CCD_HYP", "ptmPosition": pos})
        if new_mods:
            mut[0]["sequences"][1]["proteinChain"]["modifications"] = new_mods
        else:
            mut[0]["sequences"][1]["proteinChain"].pop("modifications", None)

        # write file
        out_path = os.path.join("mutants", f"CLV1_CLV3_{mut_code}.json")
        with open(out_path, "w") as f:
            json.dump(mut, f, indent=1)

