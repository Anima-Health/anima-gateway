interface StatsCardProps {
  icon: React.ReactNode;
  value: number | string;
  label: string;
  subtitle: string;
}

export default function StatsCard({ icon, value, label, subtitle }: StatsCardProps) {
  return (
    <div className="bg-white border-4 border-black shadow-brutal p-6">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="text-5xl font-black mb-2">{value}</div>
          <div className="font-black text-sm uppercase tracking-wide mb-1">{label}</div>
          <div className="text-xs text-gray-600 font-medium">{subtitle}</div>
        </div>
        <div className="text-black">{icon}</div>
      </div>
    </div>
  );
}

