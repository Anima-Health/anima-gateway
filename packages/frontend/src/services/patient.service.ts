import apiClient from '@/lib/api-client';

export interface PatientForCreate {
  name: string;
  date_of_birth: string;
  medical_record_number: string;
  gender?: string;
  address?: string;
}

export interface Patient {
  id: string;
  did: string;
  demographics: {
    name: string;
    date_of_birth: string;
    medical_record_number: string;
    gender?: string;
    address?: string;
  };
  composition: {
    uid: string;
    subject_did: string;
    category: string;
    archetype_id: string;
    name: { value: string };
    composer: string;
    content: any[];
  };
  did_metadata: {
    did: string;
    public_key: string;
    private_key: string;
    key_version: number;
    status: string;
  };
  created_at: string;
  created_by: number;
}

export const patientService = {
  /**
   * Create new patient with DID and openEHR composition
   */
  async createPatient(data: PatientForCreate): Promise<Patient> {
    const response = await apiClient.post<Patient>('/patient', data);
    return response.data;
  },

  /**
   * List all patients
   */
  async listPatients(): Promise<Patient[]> {
    const response = await apiClient.get<Patient[]>('/patient');
    return response.data;
  },

  /**
   * Get specific patient by ID
   */
  async getPatient(id: string): Promise<Patient> {
    const response = await apiClient.get<Patient>(`/patient/${id}`);
    return response.data;
  },

  /**
   * Delete patient
   */
  async deletePatient(id: string): Promise<Patient> {
    const response = await apiClient.delete<Patient>(`/patient/${id}`);
    return response.data;
  },
};

