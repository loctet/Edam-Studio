import React, { useState, useEffect } from 'react';
import CodeMirror from '@uiw/react-codemirror';
import { javascript } from '@codemirror/lang-javascript';
import { oneDark } from '@codemirror/theme-one-dark';
import { EditorView } from '@codemirror/view';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useTheme } from './ThemeProvider';
import { parseTextEDAM } from './utils/textEDAMParser';
import type { EDAMModel } from "@edams-models/edam/types";
import { useToast } from "@/components/ui/use-toast";
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertTriangle, CheckCircle2, HelpCircle, Download, Upload } from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';

interface EDAMTextEditorProps {
  value: string;
  onChange: (value: string) => void;
  onViewEDAM?: (model: EDAMModel) => void;
}

// Custom syntax highlighting for EDAM text format
const edamHighlightStyle = EditorView.theme({
  '&': {
    backgroundColor: '#000000',
    color: '#ffffff',
  },
  '.cm-content': {
    fontFamily: 'monospace',
    fontSize: '14px',
  },
  '.cm-editor': {
    height: '100%',
  },
  '.cm-scroller': {
    overflow: 'auto',
  },
}, { dark: true });

// Extension to highlight different EDAM elements
const edamSyntaxHighlight = EditorView.theme({
  '.cm-line': {
    '&:has-text([)': {
      color: '#4ade80', // Green for states
    },
    '&:has-text({)': {
      color: '#60a5fa', // Blue for pi/piPrime
    },
    '&:has-text(.)': {
      color: '#fbbf24', // Yellow for operations
    },
  },
}, { dark: true });

export const EDAMTextEditor: React.FC<EDAMTextEditorProps> = ({ 
  value, 
  onChange, 
  onViewEDAM 
}) => {
  const { theme } = useTheme();
  const { toast } = useToast();
  const [parseError, setParseError] = useState<string | null>(null);
  const [isValid, setIsValid] = useState(false);
  const [parsedModel, setParsedModel] = useState<EDAMModel | null>(null);
  const [showHelp, setShowHelp] = useState(false);

  // Example text
  const exampleText = `SimpleCounter 

O,R

counter:int, max:int

[_] {}, max>x, [] p:start(x:int, max:int){counter=x} {p:O:Top} [q1]

[q1] {p1:O:Bottom, p1:B:Bottom}, counter<max, [C2.test(counter+1)] p1:inc() {counter = counter +1} {p1:B:Top} [q1]

[q1] {p:O:Top}, counter >= max, [] p1:close() {} {} [q2]`;

  useEffect(() => {
    if (!value || value.trim().length === 0) {
      setIsValid(false);
      setParseError(null);
      setParsedModel(null);
      return;
    }

    try {
      const model = parseTextEDAM(value);
      setParsedModel(model);
      setIsValid(true);
      setParseError(null);
    } catch (error) {
      setIsValid(false);
      setParseError(error instanceof Error ? error.message : String(error));
      setParsedModel(null);
    }
  }, [value]);

  const handleLoadExample = () => {
    onChange(exampleText);
  };

  const handleViewEDAM = () => {
    if (!parsedModel) {
      toast({
        variant: "destructive",
        title: "Cannot view EDAM",
        description: "Please fix parsing errors first."
      });
      return;
    }

    if (onViewEDAM) {
      onViewEDAM(parsedModel);
      toast({
        title: "EDAM loaded",
        description: `EDAM "${parsedModel.name}" has been loaded successfully.`
      });
    }
  };

  const handleExport = () => {
    if (!value || value.trim().length === 0) {
      toast({
        variant: "destructive",
        title: "Cannot export",
        description: "Editor is empty. Please enter some EDAM content first."
      });
      return;
    }

    if (!isValid || !parsedModel) {
      toast({
        variant: "destructive",
        title: "Cannot export",
        description: "Please fix parsing errors first. The model must be valid to export."
      });
      return;
    }

    try {
      // Export the original text content directly, preserving original expressions
      const blob = new Blob([value], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${parsedModel.name.replace(/\s+/g, '_')}.edam`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      toast({
        title: "EDAM exported",
        description: `Model "${parsedModel.name}" has been exported as .edam file.`
      });
    } catch (error) {
      toast({
        variant: "destructive",
        title: "Export Error",
        description: `Error exporting model: ${error instanceof Error ? error.message : String(error)}`
      });
    }
  };

  const handleImport = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.edam';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (event) => {
        const content = event.target?.result as string;
        try {
          // Validate by parsing
          parseTextEDAM(content);
          onChange(content);
          toast({
            title: "EDAM imported",
            description: `Model "${file.name}" has been imported successfully.`
          });
        } catch (error) {
          toast({
            variant: "destructive",
            title: "Import Error",
            description: `Invalid .edam file: ${error instanceof Error ? error.message : String(error)}`
          });
        }
      };
      reader.readAsText(file);
    };
    input.click();
  };

  const extensions = [
    javascript(),
    oneDark,
    edamHighlightStyle,
    EditorView.lineWrapping,
  ];

  return (
    <Card className="h-full border-0 rounded-none flex flex-col">
      <CardHeader className="pb-3">
        <div className="flex justify-between items-center">
          <CardTitle>Manual EDAM Editor</CardTitle>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setShowHelp(!showHelp)}
            >
              <HelpCircle className="h-4 w-4 mr-2" />
              {showHelp ? 'Hide' : 'Show'} Help
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleImport}
              title="Import from .edam file"
            >
              <Upload className="h-4 w-4 mr-2" />
              Import
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleExport}
              disabled={!isValid}
              title="Export to .edam file"
            >
              <Download className="h-4 w-4 mr-2" />
              Export
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleLoadExample}
            >
              Load Example
            </Button>
            <Button
              variant="default"
              size="sm"
              onClick={handleViewEDAM}
              disabled={!isValid}
            >
              View EDAM
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent className="flex-1 flex flex-col overflow-hidden p-4">
        {showHelp && (
          <Alert className="mb-4 bg-blue-900/20 border-blue-700">
            <HelpCircle className="h-4 w-4 text-blue-400" />
            <AlertDescription className="text-blue-200">
              <div className="font-semibold mb-2 text-blue-300">How to Use the Manual EDAM Editor</div>
              <ScrollArea className="h-[400px] pr-4">
                <div className="space-y-3 text-xs">
                  <p className="text-sm mb-3">Write your EDAM model in a simple text format. The format follows this structure:</p>
                  
                  <div className="space-y-2">
                    <div>
                      <p className="font-semibold text-blue-300">1. EDAM Name (Line 1)</p>
                      <code className="block bg-gray-800 px-2 py-1 rounded mt-1">SimpleCounter</code>
                    </div>
                    
                    <div>
                      <p className="font-semibold text-blue-300">2. Roles (Line 2)</p>
                      <p className="text-xs text-gray-300 mb-1">Comma-separated list of role names</p>
                      <code className="block bg-gray-800 px-2 py-1 rounded mt-1">O,R</code>
                    </div>
                    
                    <div>
                      <p className="font-semibold text-blue-300">3. Variables (Line 3)</p>
                      <p className="text-xs text-gray-300 mb-1">Format: <code>name:type</code>, comma-separated</p>
                      <code className="block bg-gray-800 px-2 py-1 rounded mt-1">counter:int, max:int</code>
                    </div>
                    
                    <div>
                      <p className="font-semibold text-blue-300">4. Transitions (Lines 4+)</p>
                      <p className="text-xs text-gray-300 mb-1">Format:</p>
                      <code className="block bg-gray-800 px-2 py-1 rounded mt-1 text-xs">
                        [from_state] {'{'}pi{'}'}, guard, [external_calls] caller:operation(params){'{'}assignments{'}'} {'{'}piPrime{'}'} [to_state]
                      </code>
                      
                      <div className="mt-2 space-y-1 text-xs text-gray-300">
                        <p><strong className="text-blue-300">[from_state]</strong> - Source state (e.g., <code>[_]</code> or <code>[q1]</code>)</p>
                        <p><strong className="text-blue-300">{'{'}pi{'}'}</strong> - Role conditions before transition (e.g., <code>{'{'}p:O:Top{'}'}</code>)</p>
                        <p><strong className="text-blue-300">guard</strong> - Guard expression (e.g., <code>counter &lt; max</code>)</p>
                        <p><strong className="text-blue-300">[external_calls]</strong> - External calls (optional, format: <code>[Model.operation(args)]</code>)</p>
                        <p><strong className="text-blue-300">caller:operation(params)</strong> - Caller variable, operation name, and parameters</p>
                        <p><strong className="text-blue-300">{'{'}assignments{'}'}</strong> - State variable assignments (e.g., <code>{'{'}counter = counter + 1{'}'}</code>)</p>
                        <p><strong className="text-blue-300">{'{'}piPrime{'}'}</strong> - Role updates after transition</p>
                        <p><strong className="text-blue-300">[to_state]</strong> - Target state</p>
                      </div>
                      
                      <div className="mt-2">
                        <p className="text-xs text-gray-300 mb-1"><strong className="text-blue-300">Example transition:</strong></p>
                        <code className="block bg-gray-800 px-2 py-1 rounded mt-1 text-xs">
                          [q1] {'{'}p1:O:Bottom{'}'}, counter&lt;max, [C2.test(counter+1)] p1:inc() {'{'}counter = counter + 1{'}'} {'{'}p1:B:Top{'}'} [q1]
                        </code>
                      </div>
                    </div>
                    
                    <div className="mt-3 pt-2 border-t border-blue-700">
                      <p className="text-xs text-gray-300">
                        <strong className="text-blue-300">Tip:</strong> Click "Load Example" to see a complete working example, or check the parser errors below the editor for help fixing syntax issues.
                      </p>
                    </div>
                  </div>
                </div>
              </ScrollArea>
            </AlertDescription>
          </Alert>
        )}
        {parseError && (
          <Alert variant="destructive" className="mb-4">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>{parseError}</AlertDescription>
          </Alert>
        )}
        {isValid && parsedModel && (
          <Alert className="mb-4 bg-green-900/20 border-green-700">
            <CheckCircle2 className="h-4 w-4 text-green-500" />
            <AlertDescription className="text-green-200">
              Valid EDAM: {parsedModel.name} with {parsedModel.transitions.length} transitions
            </AlertDescription>
          </Alert>
        )}
        <div className="flex-1 min-h-0" style={{ height: '500px' }}>
          <CodeMirror
            value={value}
            height="500px"
            theme={oneDark}
            extensions={extensions}
            onChange={(val) => onChange(val)}
            basicSetup={{
              lineNumbers: true,
              foldGutter: true,
              dropCursor: false,
              allowMultipleSelections: false,
            }}
            style={{
              height: '500px',
              backgroundColor: '#000000',
            }}
          />
        </div>
        {!showHelp && (
          <div className="mt-4 text-sm text-gray-400">
            <p className="font-semibold mb-2">Quick Format Reference:</p>
            <ul className="list-disc list-inside space-y-1 text-xs">
              <li>Line 1: EDAM name</li>
              <li>Line 2: Roles (comma separated)</li>
              <li>Line 3: Variables (var:type, comma separated)</li>
              <li>Lines 4+: Transitions: <code className="bg-gray-800 px-1 rounded">[from] {'{'}pi{'}'}, guard, [external calls] caller:operation(params){'{'}assignments{'}'} {'{'}piPrime{'}'} [to]</code></li>
            </ul>
            <p className="text-xs mt-2 text-gray-500">Click "Show Help" above for detailed instructions and examples.</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

