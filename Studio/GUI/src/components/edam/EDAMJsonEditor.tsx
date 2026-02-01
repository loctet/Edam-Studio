import React from 'react';
import { useTheme } from './ThemeProvider';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Download, Upload, Check, AlertTriangle } from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { validateModel, exportModelAsJson } from './utils';
import type {EDAMModel} from "@edams-models/edam/types";

interface EDAMJsonEditorProps {
  value: string;
  onChange: (value: string) => void;
}

export const EDAMJsonEditor: React.FC<EDAMJsonEditorProps> = ({ value, onChange }) => {
  const { theme } = useTheme();
  const [isValid, setIsValid] = React.useState(true);
  const [validationErrors, setValidationErrors] = React.useState<string[]>([]);
  const [jsonError, setJsonError] = React.useState<string | null>(null);

  React.useEffect(() => {
    try {
      const model = JSON.parse(value) as EDAMModel;
      const errors = validateModel(model);
      setValidationErrors(errors);
      setIsValid(errors.length === 0);
      setJsonError(null);
    } catch (error) {
      setIsValid(false);
      setJsonError((error as Error).message);
    }
  }, [value]);

  const handleExport = () => {
    try {
      const model = JSON.parse(value) as EDAMModel;
      exportModelAsJson(model);
    } catch (error) {
      console.error('Error exporting model:', error);
    }
  };

  const handleImport = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (event) => {
        const content = event.target?.result as string;
        try {
          JSON.parse(content);
          onChange(content);
        } catch (error) {
          setJsonError('Invalid JSON file');
        }
      };
      reader.readAsText(file);
    };
    input.click();
  };

  return (
    <Card className={`h-full border-0 rounded-none ${theme === 'dark' ? 'bg-gray-900' : 'bg-gray-50'}`}>
      <CardHeader className="p-2 flex-row items-center justify-between">
        <CardTitle className="text-sm font-medium">JSON Editor</CardTitle>
        <div className="flex space-x-1">
          {isValid ? (
            <div className="text-xs flex items-center text-green-500">
              <Check className="h-3 w-3 mr-1" />Syntax Valid
            </div>
          ) : (
            <div className="text-xs flex items-center text-amber-500">
              <AlertTriangle className="h-3 w-3 mr-1" />Syntax Invalid
            </div>
          )}
          <Button
            size="sm"
            variant="ghost"
            className="h-7 w-7 p-0"
            title="Import JSON"
            onClick={handleImport}
          >
            <Upload className="h-3.5 w-3.5" />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            className="h-7 w-7 p-0"
            title="Export JSON"
            onClick={handleExport}
            disabled={!isValid}
          >
            <Download className="h-3.5 w-3.5" />
          </Button>
        </div>
      </CardHeader>
      <CardContent className="p-0 h-[calc(100%-40px)]">
        <ScrollArea className="h-full">
          <Textarea
            value={value}
            onChange={(e) => onChange(e.target.value)}
            className={`font-mono text-sm min-h-[300px] w-full resize-none rounded-none border-0 ${
              theme === 'dark' ? 'bg-gray-800 text-gray-100' : 'bg-white text-gray-900'
            } ${!isValid ? 'border-l-2 border-l-amber-500' : ''}`}
            placeholder="Enter EDAM model in JSON format..."
          />
          
          {(jsonError || validationErrors.length > 0) && (
            <div className={`text-xs p-2 overflow-auto max-h-20 ${
              theme === 'dark' ? 'bg-gray-800 text-red-300' : 'bg-red-50 text-red-800'
            }`}>
              {jsonError && <div className="font-medium">JSON Error: {jsonError}</div>}
              {validationErrors.length > 0 && (
                <div>
                  <div className="font-medium">Validation Errors:</div>
                  <ul className="list-disc ml-4 mt-1">
                    {validationErrors.map((error, index) => (
                      <li key={index}>{error}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}
        </ScrollArea>
      </CardContent>
    </Card>
  );
};
