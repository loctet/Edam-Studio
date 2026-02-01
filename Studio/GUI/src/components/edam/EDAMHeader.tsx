import React from 'react';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Moon, Sun, HelpCircle, Plus, Download, Upload, Code, Settings, Send } from 'lucide-react';
import { useTheme } from './ThemeProvider';
import type {EDAMModel} from "@edams-models/edam/types";

interface EDAMHeaderProps {
  models: EDAMModel[];
  selectedModel: EDAMModel | null;
  onModelSelect: (model: EDAMModel) => void;
  onCreateNewModel: () => void;
  onCreateNewModelAI?: () => void;
  onExportModel: () => void;
  onImportModel: () => void;
  onHelp: () => void;
  onExportOcaml: () => void;
  onGenerateCode?: () => void;
  onOpenConfig?: () => void;
  isGenerating?: boolean;
}

export const EDAMHeader: React.FC<EDAMHeaderProps> = ({ 
  models, 
  selectedModel,
  onModelSelect, 
  onCreateNewModel,
  onCreateNewModelAI,
  onExportModel,
  onImportModel,
  onHelp,
  onExportOcaml,
  onGenerateCode,
  onOpenConfig,
  isGenerating = false
}) => {
  const { theme, setTheme } = useTheme();

  return (
    <header className={`p-4 flex items-center justify-between border-b ${theme === 'dark' ? 'bg-gray-800 text-white border-gray-700' : 'bg-white text-gray-900 border-gray-200'}`}>
      <div className="flex items-center space-x-4">
        <h1 className="text-xl font-bold">EDAM Modeling Studio</h1>
        
        <div className="w-64">
          <Select 
            value={selectedModel?.name} 
            onValueChange={(value) => {
              const model = models.find(m => m.name === value);
              if (model) onModelSelect(model);
            }}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select a model" />
            </SelectTrigger>
            <SelectContent>
              {models.map((model) => (
                <SelectItem key={model.name} value={model.name}>{model.name}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        
        <Button
          variant="outline"
          size="sm"
          onClick={onCreateNewModel}
          title="Create new model"
          className="flex items-center text-xs"
        >
          <Plus className="h-3.5 w-3.5 mr-1" />
          New
        </Button>
        {
          /*
        <Button
          variant="outline"
          size="sm"
          onClick={onCreateNewModelAI}
          title="Create new model using AI"
          className="flex items-center text-xs"
        >
          <Plus className="h-3.5 w-3.5 mr-1" />
          New (AI)
        </Button>
        */
        }
        {onGenerateCode && (
          <Button
            variant="default"
            size="sm"
            onClick={onGenerateCode}
            disabled={isGenerating}
            className="flex items-center text-xs"
          >
            <Send className="h-3.5 w-3.5 mr-1" />
            {isGenerating ? 'Generating...' : 'Generate Code'}
          </Button>
        )}
      </div>
      
      <div className="flex items-center space-x-2">
        {onOpenConfig && (
          <Button
            variant="ghost"
            size="icon"
            onClick={onOpenConfig}
            title="Configuration Settings"
          >
            <Settings className="h-5 w-5" />
          </Button>
        )}
        
        <Button
          variant="ghost"
          size="icon"
          onClick={onImportModel}
          title="Import model"
        >
          <Upload className="h-5 w-5" />
        </Button>
        
        <Button
          variant="ghost"
          size="icon"
          onClick={onExportModel}
          title="Export model"
          disabled={!selectedModel}
        >
          <Download className="h-5 w-5" />
        </Button>
        
        <Button
          variant="ghost"
          size="icon"
          onClick={onExportOcaml}
          title="Export as OCaml"
          disabled={!selectedModel}
        >
          <Code className="h-5 w-5" />
        </Button>
        
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          title={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
        >
          {theme === 'dark' ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
        </Button>
        
        <Button
          variant="ghost"
          size="icon"
          onClick={onHelp}
          title="Help"
        >
          <HelpCircle className="h-5 w-5" />
        </Button>
      </div>
    </header>
  );
};
