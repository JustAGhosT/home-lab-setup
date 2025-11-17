import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { invoke } from '../utils/invoke';
import type { AppDispatch } from './store';

interface ConfigState {
  config: any;
  loading: boolean;
  error: string | null;
}

const initialState: ConfigState = {
  config: null,
  loading: false,
  error: null,
};

const configSlice = createSlice({
  name: 'config',
  initialState,
  reducers: {
    fetchConfigStart(state) {
      state.loading = true;
      state.error = null;
    },
    fetchConfigSuccess(state, action: PayloadAction<any>) {
      state.config = action.payload;
      state.loading = false;
    },
    fetchConfigFailure(state, action: PayloadAction<string>) {
      state.error = action.payload;
      state.loading = false;
    },
    setConfigValue(state, action: PayloadAction<{ key: string; value: any }>) {
      state.config[action.payload.key] = action.payload.value;
    },
  },
});

export const {
  fetchConfigStart,
  fetchConfigSuccess,
  fetchConfigFailure,
  setConfigValue,
} = configSlice.actions;

export const fetchConfig = () => async (dispatch: AppDispatch) => {
  dispatch(fetchConfigStart());
  try {
    const result = await invoke('pwsh', ['-Command', 'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Get-Configuration | ConvertTo-Json']);
    dispatch(fetchConfigSuccess(JSON.parse(result)));
  } catch (error) {
    if (error instanceof Error) {
        dispatch(fetchConfigFailure(error.message));
      } else {
        dispatch(fetchConfigFailure(String(error)));
      }
  }
};

export const saveConfig = (config: any) => async (_dispatch: AppDispatch) => {
  try {
    await invoke('pwsh', ['-Command', `Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Set-Configuration -Configuration '${JSON.stringify(config)}'`]);
  } catch (error) {
    console.error(error);
  }
};

export default configSlice.reducer;
