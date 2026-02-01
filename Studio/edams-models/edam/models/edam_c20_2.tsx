import type { EDAMModel } from "../types";
import edam_c20 from "./edam_c20";

const edam_c20_2: EDAMModel =  structuredClone(edam_c20);
edam_c20_2.name = "C20_2";


export default edam_c20_2;


