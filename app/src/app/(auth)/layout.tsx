export default function AuthLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <div className="min-h-screen bg-[var(--bg-primary)]">
            {/* Background decoration */}
            <div className="fixed inset-0 pointer-events-none overflow-hidden">
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[400px] bg-[var(--gold-500)] rounded-full blur-[200px] opacity-5"></div>
                <div className="absolute bottom-0 right-0 w-[400px] h-[400px] bg-[var(--gold-600)] rounded-full blur-[150px] opacity-5"></div>
            </div>

            {/* Content */}
            <div className="relative z-10">
                {children}
            </div>
        </div>
    );
}
