import { useState } from 'react';
import { Lock, UserCircle, AlertCircle, CheckCircle } from 'lucide-react';
import { authService } from '@/services/auth.service';

interface LoginPageProps {
  onLoginSuccess: (did: string) => void;
}

export default function LoginPage({ onLoginSuccess }: LoginPageProps) {
  const [did, setDid] = useState('did:iota:anima:abc123');
  const [step, setStep] = useState<'input' | 'challenge' | 'signing'>('input');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [nonce, setNonce] = useState('');

  const handleRequestChallenge = async () => {
    setLoading(true);
    setError('');
    
    try {
      const challenge = await authService.requestChallenge(did);
      setNonce(challenge.nonce);
      setStep('challenge');
      console.log('Challenge received:', challenge);
    } catch (err: any) {
      setError(err.response?.data?.error?.type || 'Failed to request challenge');
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = async () => {
    setLoading(true);
    setError('');
    setStep('signing');
    
    try {
      // For demo: Using mock signature
      // In production: User signs with their DID private key
      const signature = 'mock_signature_for_demo';
      
      const result = await authService.login({
        did,
        nonce,
        signature,
      });
      
      console.log('Login successful:', result);
      
      // Small delay to show success message
      setTimeout(() => {
        onLoginSuccess(did);
      }, 1000);
    } catch (err: any) {
      setError(err.response?.data?.error?.type || 'Authentication failed');
      setStep('challenge');
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-2xl">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-7xl font-black mb-4 tracking-tight">
            ANIMA
            <br />
            HEALTH
          </h1>
          <div className="inline-block px-4 py-2 bg-black text-white border-4 border-black">
            <p className="font-bold uppercase text-sm tracking-wider">
              IOTA DID AUTHENTICATION POC
            </p>
          </div>
        </div>

        {/* Login Card */}
        <div className="card-brutal">
          <div className="mb-6">
            <h2 className="text-3xl font-black mb-2">
              {step === 'input' && 'LOG IN'}
              {step === 'challenge' && 'SIGN CHALLENGE'}
              {step === 'signing' && 'VERIFYING...'}
            </h2>
            <p className="text-gray-600 font-medium">
              {step === 'input' && 'No passwords required. Just cryptographic proof.'}
              {step === 'challenge' && 'Sign the challenge with your DID private key'}
              {step === 'signing' && 'Verifying signature against IOTA Tangle...'}
            </p>
          </div>

          {/* Error Display */}
          {error && (
            <div className="bg-black text-white border-4 border-black p-4 mb-6">
              <div className="flex items-center gap-2">
                <AlertCircle size={20} />
                <span className="font-bold uppercase text-sm">{error}</span>
              </div>
            </div>
          )}

          {/* DID Input */}
          {step === 'input' && (
            <>
              <div className="mb-6">
                <label className="block mb-2 font-bold uppercase text-sm tracking-wide">
                  <UserCircle className="inline mr-2" size={16} />
                  Your DID
                </label>
                <input
                  type="text"
                  value={did}
                  onChange={(e) => setDid(e.target.value)}
                  className="input-brutal font-mono text-sm"
                  placeholder="did:iota:anima:abc123"
                />
                <p className="mt-2 text-xs text-gray-500 font-medium">
                  Using IOTA Identity (identity_iota v1.6.0-beta)
                </p>
              </div>

              <button
                onClick={handleRequestChallenge}
                disabled={loading || !did}
                className="btn-brutal w-full flex items-center justify-center gap-2"
              >
                <Lock size={20} />
                {loading ? 'REQUESTING CHALLENGE...' : 'REQUEST CHALLENGE'}
              </button>
            </>
          )}

          {/* Challenge Display */}
          {step === 'challenge' && (
            <>
              <div className="mb-6">
                <div className="bg-black text-white border-4 border-black p-4 mb-4">
                  <div className="flex items-center gap-2 mb-2">
                    <CheckCircle size={20} />
                    <span className="font-black uppercase text-sm">Challenge Received!</span>
                  </div>
                  <div className="font-mono text-xs break-all">{nonce}</div>
                </div>

                <div className="bg-gray-100 border-4 border-black p-4">
                  <h4 className="font-black text-sm mb-2">SIGN THIS MESSAGE:</h4>
                  <div className="font-mono text-sm break-all mb-3">
                    Anima Health Auth:{nonce}
                  </div>
                  <p className="text-xs font-medium text-gray-600">
                    With your DID's Ed25519 private key
                  </p>
                </div>
              </div>

              <button
                onClick={handleLogin}
                disabled={loading}
                className="btn-brutal w-full flex items-center justify-center gap-2"
              >
                <Lock size={20} />
                {loading ? 'SIGNING & VERIFYING...' : 'SUBMIT SIGNATURE (DEMO)'}
              </button>

              <button
                onClick={() => {
                  setStep('input');
                  setNonce('');
                }}
                className="btn-brutal-secondary w-full mt-3"
              >
                BACK
              </button>
            </>
          )}

          {/* Signing State */}
          {step === 'signing' && (
            <div className="text-center py-8">
              <div className="inline-block animate-pulse mb-4">
                <Lock size={48} />
              </div>
              <p className="font-bold text-lg">Verifying signature...</p>
              <p className="text-sm text-gray-600 mt-2">
                Resolving DID from IOTA Tangle
              </p>
            </div>
          )}

          {/* Auth Flow Info */}
          {step === 'input' && (
            <div className="bg-gray-100 border-4 border-black p-4 mt-6">
              <h3 className="font-black uppercase text-sm mb-3">AUTHENTICATION FLOW:</h3>
              <ol className="space-y-2 text-sm">
                <li className="flex items-start">
                  <span className="font-black mr-2">1.</span>
                  <span>Request challenge nonce (5min expiry)</span>
                </li>
                <li className="flex items-start">
                  <span className="font-black mr-2">2.</span>
                  <span>Sign with Ed25519 private key</span>
                </li>
                <li className="flex items-start">
                  <span className="font-black mr-2">3.</span>
                  <span>Verify signature against Tangle</span>
                </li>
                <li className="flex items-start">
                  <span className="font-black mr-2">4.</span>
                  <span>Get 24h access token</span>
                </li>
              </ol>
            </div>
          )}

          {/* Features */}
          <div className="mt-8 pt-6 border-t-4 border-black">
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <div className="font-black text-2xl mb-1">0</div>
                <div className="text-xs font-bold uppercase">Passwords</div>
              </div>
              <div>
                <div className="font-black text-2xl mb-1">100%</div>
                <div className="text-xs font-bold uppercase">Blockchain</div>
              </div>
              <div>
                <div className="font-black text-2xl mb-1">∞</div>
                <div className="text-xs font-bold uppercase">Privacy</div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="text-center mt-8">
          <p className="text-sm font-medium text-gray-600">
            Powered by <span className="font-black">IOTA</span> • 
            <span className="font-black"> For MOVEATHON Europe 2025</span> •
            <span className="font-black"> By Akanimoh Osutuk</span>
          </p>
        </div>
      </div>
    </div>
  );
}
