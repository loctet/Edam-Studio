import type { EDAMModel } from "./types";
export type { EDAMModel, EDAMTransition, ExternalCall } from "./types";
import edam_assettransfer from "./models/edam_assettransfer";
import edam_basicprovenance from "./models/edam_basicprovenance";
import edam_defectivecounter from "./models/edam_defectivecounter";
import edam_digital_locker from "./models/edam_digitallocker";
import edam_frequentflyer from "./models/edam_frequentflyer";
import edam_helloblockchain from "./models/edam_helloblockchain";
import edam_refrigeratedtransport from "./models/edam_refrigeratedtransport";
import edam_thermostatoperation from "./models/edam_thermostatoperation";
import { edam_simplemarketplace } from "./models/edam_simplemarketplace";

// Added models for the paper
import edam_amm from "./models/edam_amm";
import edam_c20 from "./models/edam_c20";
import edam_simplewallet from "./models/edam_simplewallet";
import edam_c20_2 from "./models/edam_c20_2";

// Models for examples in the paper
import { edam_c1, edam_c2, edam_c3} from "./models/edam_model1_2_3"; 
import edam_cpay from "./models/edam_cpay";
import edam_cop from "./models/edam_cop";
import { edam_cm } from "./models/edam_cm";

export const edam_models:Record<string, EDAMModel> = {
    edam_assettransfer,
    edam_basicprovenance,
    edam_defectivecounter,
    edam_digital_locker,
    edam_frequentflyer,
    edam_helloblockchain,
    edam_refrigeratedtransport,
    edam_simplemarketplace,
    edam_thermostatoperation,
    // Added models for the paper
    edam_amm,
    edam_simplewallet,
    edam_c20,
    edam_c20_2,
    // Models for examples in the paper
    edam_c1,
    edam_c2,
    edam_c3,
    edam_cm,
    edam_cop,
    edam_cpay
}
