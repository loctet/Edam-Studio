import type { EDAMModel } from "../types";

const edam_amm: EDAMModel = {
  name: "AMM",
  states: ["S_Deployed", "S_LiquidityAdded"],
  transitions: [
      {
          from: "_",
          guard: ['Val (BoolVal(true))', []],
          rho: [],
          ptpVarList: [],
          ptpVar: "owner",
          operation: "start",
          paramVar: {},
          assignments: {
              "reserveA": "Val(IntVal(0))",
              "reserveB": "Val(IntVal(0))",
              "reserveA_": "Val(IntVal(0))",
              "reserveB_": "Val(IntVal(0))",
              "lpTotalSupply": "Val(IntVal(0))",
              "lpTotalSupply_": "Val(IntVal(0))",
              "swapFees": "Val(IntVal(0))"
          },
          rhoPrime: [
              { user: "owner", role: "owner", mode: "Top" }
          ],
          to: "S_Deployed"
      },
      {
          from: "S_Deployed",
          guard: [
              `And(
                  GreaterThan(Dvar(Var("_amountA")), Val(IntVal(0))),
                  And(
                      GreaterThan(Dvar(Var("_amountB")), Val(IntVal(0))),
                      And(
                          Equal(Dvar(Var("reserveA")), Val(IntVal(0))),
                          And(
                              Equal(Dvar(Var("reserveB")), Val(IntVal(0))),
                              GreaterThan(Plus(Dvar(Var("_amountA")), Dvar(Var("_amountB"))), Val(IntVal(0)))
                          )   
                      )
                  )
              )`,
              [
                  {
                    type: 'externalCall',
                    modelName: 'C20',
                    operation: 'transferFrom',
                    args: [
                      ['PtID(Ptp("user"))', 'PtID(Ptp("AMM"))'],
                      ['Dvar(Var("_amountA"))']
                    ],
                    enabled: true
                  },
                  {
                    type: 'externalCall',
                    modelName: 'C20_2',
                    operation: 'transferFrom',
                    args: [
                      ['PtID(Ptp("user"))', 'PtID(Ptp("AMM"))'],
                      ['Dvar(Var("_amountB"))']
                    ],
                    enabled: true
                  }
                ]
          ],
          rho: [],
          ptpVarList: [],
          ptpVar: "user",
          operation: "addLiquidity",
          paramVar: {
              "_amountA": "int",
              "_amountB": "int"
          },
          assignments: {
              "reserveA": 'Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))',
              "reserveB": 'Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))',
              "lpTotalSupply": 'Plus(Dvar(Var("lpTotalSupply")), Plus(Dvar(Var("_amountA")), Dvar(Var("_amountB"))))',
              "lpBalances": 'FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Plus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), Plus (Dvar (Var "_amountA"), Dvar (Var "_amountB")))])',
              "reserveA_": 'Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))',
              "reserveB_": 'Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))',
              "lpTotalSupply_": 'Plus(Dvar(Var("lpTotalSupply_")), Plus(Dvar(Var("_amountA")), Dvar(Var("_amountB"))))'
          },
          rhoPrime: [
              { user: "user", role: "liquidity_provider", mode: "Top" }
          ],
          to: "S_LiquidityAdded"
      },
      {
          from: "S_LiquidityAdded",
          guard: [
              `And(
                  GreaterThan(Dvar(Var("_amountA")), Val(IntVal(0))),
                  And(
                      GreaterThan(Dvar(Var("_amountB")), Val(IntVal(0))),
                      And(
                          Not(And(Equal(Dvar(Var("reserveA")), Val(IntVal(0))), Equal(Dvar(Var("reserveB")), Val(IntVal(0))))),
                          And(
                              Equal(Times(Dvar(Var("reserveA")), Dvar(Var("_amountB"))), Times(Dvar(Var("reserveB")), Dvar(Var("_amountA")))),
                              GreaterThan(Plus(Dvar(Var("_amountA")), Dvar(Var("_amountB"))), Val(IntVal(0)))
                          )
                      )
                  )
              )`,
              [
                  {
                    type: 'externalCall',
                    modelName: 'C20',
                    operation: 'transferFrom',
                    args: [
                      ['PtID(Ptp("user"))', 'PtID(Ptp("AMM"))'],
                      ['Dvar(Var("_amountA"))']
                    ],
                    enabled: true
                  },
                  {
                    type: 'externalCall',
                    modelName: 'C20_2',
                    operation: 'transferFrom',
                    args: [
                      ['PtID(Ptp("user"))', 'PtID(Ptp("AMM"))'],
                      ['Dvar(Var("_amountB"))']
                    ],
                    enabled: true
                  }
              ]
          ],
          rho: [],
          ptpVarList: [],
          ptpVar: "user",
          operation: "addLiquidity",
          paramVar: {
              "_amountA": "int",
              "_amountB": "int"
          },
          assignments: {
              "reserveA": 'Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))',
              "reserveB": 'Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))',
              "lpTotalSupply": 'Plus(Dvar(Var("lpTotalSupply_")), FuncCall("min", [Divide(Times(Dvar(Var("_amountA")), Dvar(Var("lpTotalSupply_"))), Dvar(Var("reserveA_"))); Divide(Times(Dvar(Var("_amountB")), Dvar(Var("lpTotalSupply_"))), Dvar(Var("reserveB_")))]))',
              "lpBalances": ' FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Plus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), FuncCall ("min", [Divide (Times (Dvar (Var "_amountA"), Dvar (Var "lpTotalSupply_")), Dvar (Var "reserveA_")); Divide (Times (Dvar (Var "_amountB"), Dvar (Var "lpTotalSupply_")), Dvar (Var "reserveB_"))]))])',
              "reserveA_": 'Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))',
              "reserveB_": 'Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))',
              "lpTotalSupply_": 'Plus(Dvar(Var("lpTotalSupply_")), FuncCall("min", [Divide(Times(Dvar(Var("_amountA")), Dvar(Var("lpTotalSupply_"))), Dvar(Var("reserveA_"))); Divide(Times(Dvar(Var("_amountB")), Dvar(Var("lpTotalSupply_"))), Dvar(Var("reserveB_")))]))'
          },
          rhoPrime: [
              { user: "user", role: "liquidity_provider", mode: "Top" }
          ],
          to: "S_LiquidityAdded"
      },
      {
          from: "S_LiquidityAdded",
          guard: [
              `And(
                  GreaterThan(Dvar(Var("_lpAmount")), Val(IntVal(0))),
                  GreaterThanEqual(
                      MapIndex(Dvar(Var("lpBalances")), PtID(Ptp("user")), Val(IntVal(0))),
                      Dvar(Var("_lpAmount"))
                  )
              )`,
              [
                  {
                    type: 'externalCall',
                    modelName: 'C20_2',
                    operation: 'transfer',
                    args: [
                      ['PtID(Ptp("user"))'],
                      ['Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveB"))), Dvar(Var("lpTotalSupply")))']
                    ],
                    enabled: true
                  },
                  {
                    type: 'externalCall',
                    modelName: 'C20',
                    operation: 'transfer',
                    args: [
                      ['PtID(Ptp("user"))'],
                      ['Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveA"))), Dvar(Var("lpTotalSupply")))']
                    ],
                    enabled: true
                  }
                ]
          ],
          rho: [
              { user: "user", role: "liquidity_provider", mode: "Top" }
          ],
          ptpVarList: [],
          ptpVar: "user",
          operation: "removeLiquidity",
          paramVar: {
              "_lpAmount": "int"
          },
          assignments: {
              "reserveA": 'Minus(Dvar(Var("reserveA_")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveA_"))), Dvar(Var("lpTotalSupply_"))))',
              "reserveB": 'Minus(Dvar(Var("reserveB_")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveB_"))), Dvar(Var("lpTotalSupply_"))))',
              "lpTotalSupply": 'Minus(Dvar(Var("lpTotalSupply_")), Dvar(Var("_lpAmount")))',
              "lpBalances": 'FuncCall ("update_map", [Dvar (Var "lpBalances"); PtID (Ptp "user"); Minus (MapIndex (Dvar (Var "lpBalances"), PtID (Ptp "user"), Val (IntVal 0)), Dvar (Var "_lpAmount"))])',
              "reserveA_": 'Minus(Dvar(Var("reserveA_")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveA_"))), Dvar(Var("lpTotalSupply_"))))',
              "reserveB_": 'Minus(Dvar(Var("reserveB_")), Divide(Times(Dvar(Var("_lpAmount")), Dvar(Var("reserveB_"))), Dvar(Var("lpTotalSupply_"))))',
              "lpTotalSupply_": 'Minus(Dvar(Var("lpTotalSupply_")), Dvar(Var("_lpAmount")))',
          },
          rhoPrime: [],
          to: "S_LiquidityAdded"
      },
      {
          from: "S_LiquidityAdded",
          guard: [
              `GreaterThan(
                  Times(Dvar(Var("reserveA")), Dvar(Var("reserveB"))),
                  Val(IntVal(0))
              )`,
              [
                  {
                    type: 'externalCall',
                    modelName: 'C20',
                    operation: 'transferFrom',
                    args: [
                      ['PtID(Ptp("user"))', 'PtID(Ptp("AMM"))'],
                      ['Dvar(Var("_amountA"))']
                    ],
                    enabled: true
                  },
                  {
                    type: 'externalCall',
                    modelName: 'C20_2',
                    operation: 'transfer',
                    args: [
                      ['PtID(Ptp("user"))'],
                      ['FuncCall("get_amount_out", [Dvar(Var("_amountA")); Dvar(Var("reserveA")); Dvar(Var("reserveB")); Dvar(Var("swapFees"))])']
                    ],
                    enabled: true
                  }
                ]
          ],
          rho: [],
          ptpVarList: [],
          ptpVar: "user",
          operation: "swapAForB",
          paramVar: {
              "_amountA": "int"
          },
          assignments: {
              "reserveA": 'Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))',
              "reserveB": 'Minus (Dvar (Var "reserveB_"), FuncCall("get_amount_out", [Dvar (Var "_amountA"); Dvar (Var "reserveA_"); Dvar (Var "reserveB_"); Dvar (Var "swapFees")]))',
              "reserveB_": 'Minus (Dvar (Var "reserveB_"), FuncCall("get_amount_out", [Dvar (Var "_amountA"); Dvar (Var "reserveA_"); Dvar (Var "reserveB_"); Dvar (Var "swapFees")]))',
              "reserveA_": 'Plus(Dvar(Var("reserveA_")), Dvar(Var("_amountA")))',
          },
          rhoPrime: [],
          to: "S_LiquidityAdded"
      },
      {
          from: "S_LiquidityAdded",
          guard: [
              `GreaterThan(
                  Times(Dvar(Var("reserveA")), Dvar(Var("reserveB"))),
                  Val(IntVal(0))
              )`,
              [
                  {
                    type: 'externalCall',
                    modelName: 'C20_2',
                    operation: 'transferFrom',
                    args: [
                      ['PtID(Ptp("user"))', 'PtID(Ptp("AMM"))'],
                      ['Dvar(Var("_amountB"))']
                    ],
                    enabled: true
                  },
                  {
                    type: 'externalCall',
                    modelName: 'C20',
                    operation: 'transfer',
                    args: [
                      ['PtID(Ptp("user"))'],
                      ['FuncCall("get_amount_out", [Dvar(Var("_amountB")); Dvar(Var("reserveB")); Dvar(Var("reserveA")); Dvar(Var("swapFees"))])']
                    ],
                    enabled: true
                  }
                ]
              
          ],
          rho: [],
          ptpVarList: [],
          ptpVar: "user",
          operation: "swapBForA",
          paramVar: {
              "_amountB": "int"
          },
          assignments: {
              "reserveA": 'Minus (Dvar (Var "reserveA_"), FuncCall("get_amount_out", [Dvar (Var "_amountB"); Dvar (Var "reserveB_"); Dvar (Var "reserveA_"); Dvar (Var "swapFees")]))',
              "reserveB": 'Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))',
              "reserveA_": 'Minus (Dvar (Var "reserveA_"), FuncCall("get_amount_out", [Dvar (Var "_amountB"); Dvar (Var "reserveB_"); Dvar (Var "reserveA_"); Dvar (Var "swapFees")]))',
              "reserveB_": 'Plus(Dvar(Var("reserveB_")), Dvar(Var("_amountB")))',
          },
          rhoPrime: [],
          to: "S_LiquidityAdded"
      }
  ],
  initialState: "_",
  finalStates: [],
  roles: ["owner", "liquidity_provider", "swapper"],
  variablesList: ["reserveA", "reserveB", "lpBalances"],
  participantsList: {},
  variables: {
      "reserveA": "int",
      "reserveB": "int",
      "lpBalances": "map_address_int",
      "lpTotalSupply": "int",
      "swapFees": "int",
      "reserveA_": "int",
      "reserveB_": "int",
      "lpTotalSupply_": "int",
      "_temp": "int",
      "C20": "C20",
      "C20_2": "C20_2"
  }
};

export default edam_amm;
