
import React from 'react';
import EDAMEditor from '../components/edam/EDAMEditor';
import { ThemeProvider } from '../components/edam/ThemeProvider';

const Index = () => {
  return (
    <ThemeProvider>
      <EDAMEditor />
    </ThemeProvider>
  );
};

export default Index;
