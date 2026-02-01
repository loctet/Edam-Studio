
import React from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card } from '@/components/ui/card';
import { Alert, AlertTitle, AlertDescription } from '@/components/ui/alert';
import { CheckCircle, Download, TestTube } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';

interface CodeGenerationResultsProps {
  codeError: string | null;
  generatedCode: string[];
  generatedImages: string[];
  emptyRoleCheck: string[];
  emptyRoleCheckIssues: [string, string][];
  testingResultData: string | null
  downloadLink: string | null;
  isGenerating: boolean,
  onDownload: () => void;
  onRunTestFile: () => void;

}

const CodeGenerationResults: React.FC<CodeGenerationResultsProps> = ({
  codeError,
  generatedCode,
  generatedImages,
  emptyRoleCheck,
  emptyRoleCheckIssues,
  testingResultData,
  downloadLink,
  onDownload, 
  onRunTestFile,
  isGenerating,
}) => {
  if (!codeError && generatedCode.length === 0 && generatedImages.length === 0) {
    return null;
  }

  return (
    <div className="mt-8 space-y-4">
      <h2 className="text-2xl font-bold">Generation Results</h2>
      
      {codeError && (
        <Alert variant="destructive">
          <AlertTitle>Error generating file</AlertTitle>
          <AlertDescription className="whitespace-pre-wrap">
            {codeError}
          </AlertDescription>
        </Alert>
      )}
      
      {
       /*emptyRoleCheck.length > 0 && emptyRoleCheckIssues.length > 0 && (
        <Alert>
          <AlertTitle>Empty Role Check</AlertTitle>
          <div className="space-y-4 mt-2">
            {emptyRoleCheckIssues.map((item, index) => (
              <div key={index} className="border p-4 rounded-md">
                <h3 className="font-semibold">{item[0]}</h3>
                <div className="mt-2">
                  {item[1] ? (
                    <div dangerouslySetInnerHTML={{__html: item[1]}} />
                  ) : (
                    <div>No issues found</div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </Alert>
      ) */
        }
      
      {(generatedImages.length > 0 || generatedCode.length > 0) && (
        <Tabs defaultValue="code" className="w-full">
          <TabsList>
            <TabsTrigger value="code">Generated Code</TabsTrigger>
            {/* <TabsTrigger value="diagrams">FSM Diagrams</TabsTrigger> */}
            <TabsTrigger value="testsrun">Run Solidity Test</TabsTrigger>
          </TabsList>
          
          <TabsContent value="code">
            <Card className="p-4">
              {downloadLink && (
                <div className="mb-4">
                  <Button onClick={onDownload} className="flex items-center gap-2">
                    <Download size={16} />
                    Download Generated ZIP
                  </Button>
                </div>
              )}
              
              {generatedCode.map((content, index) => (
                <div key={index} className="mt-4">
                  <SyntaxHighlighter language="solidity" style={vscDarkPlus} showLineNumbers>
                    {content}
                  </SyntaxHighlighter>
                </div>
              ))}
            </Card>
          </TabsContent>
          
          <TabsContent value="diagrams">
            <Card className="p-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {generatedImages.map((image, index) => (
                  <div key={index} className="border rounded-md overflow-hidden">
                    <a href={image} target="_blank" rel="noreferrer">
                      <img src={image} alt={`Generated FSM ${index}`} className="w-full" />
                    </a>
                  </div>
                ))}
              </div>
            </Card>
          </TabsContent>

          <TabsContent value="testsrun">
            <Card className="p-4">
                {downloadLink && (
                  <div className="mb-4">
                    <Button onClick={onRunTestFile} 
                    className="flex items-center gap-2"
                    disabled={isGenerating}
                    >
                      <TestTube size={16} />
                      {isGenerating? "Generating tests" : "Run Solidity Tests" }
                    </Button>
                  </div>
                )}
                <div className="mb-12">
                  {testingResultData ? (
                    <div className="">
                      <h3 className="text-lg font-semibold mb-2">Test Results</h3>
                      
                      {/* Split the data by newline and render each line separately */}
                      <div className="text-gray-800">
                        {testingResultData.split("\n").map((line, index) => {
                          if (line.includes("✓")) {
                            return (
                              <div key={index} className="text-green-500">
                                <div className="flex items-center gap-2">
                                  <CheckCircle size={18} />
                                  <span>{line}</span>
                                </div>
                              </div>
                            );
                          } else if (line.includes("passing")) {
                            return (
                              <div key={index} className="text-green-600">
                                <div className="font-semibold">Tests Passed</div>
                                <span>{line}</span>
                              </div>
                            );
                          } else if (line.includes("failing")) {
                            return (
                              <div key={index} className="text-red-500">
                                <div className="font-semibold">Tests Failed</div>
                                <span>{line}</span>
                              </div>
                            );
                          } else {
                            return (
                              <div key={index} className="text-gray-600">
                                <span>{line}</span>
                              </div>
                            );
                          }
                        })}
                      </div>
                    </div>
                  ) : (
                    <div className="text-gray-600">
                      <p>No test results available. Run the tests to view the results.</p>
                    </div>
                  )}
                </div>
            </Card>
          </TabsContent>
        </Tabs>
      )}
    </div>
  );
};

export default CodeGenerationResults;
