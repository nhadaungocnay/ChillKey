import SwiftUI

public struct SettingsView: View {
    @ObservedObject var state = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Text("CK")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("ChillKey")
                        .font(.headline)
                    Text("Bộ gõ tiếng Việt Native cho macOS Chip M")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Settings Form
            Form {
                Section(header: Text("Chế độ gõ & Quy tắc")) {
                    Picker("Kiểu gõ:", selection: $state.inputMethod) {
                        ForEach(InputMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Đặt dấu thanh:", selection: $state.tonePlacementStyle) {
                        ForEach(TonePlacementStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }
                
                Section(header: Text("Phím tắt")) {
                    HStack {
                        Text("Chuyển đổi Anh / Việt:")
                        Spacer()
                        Text("Control + Shift")
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
                
                Section(header: Text("Quyền hệ thống")) {
                    HStack {
                        Text("Quyền Accessibility:")
                        Spacer()
                        if state.hasAccessibilityPermission {
                            Label("Đã cấp quyền", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            HStack {
                                Label("Chưa cấp quyền", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Button("Cấp quyền") {
                                    PermissionManager.openAccessibilitySettings()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding(.top, 4)
            
            Divider()
            
            // Footer
            HStack {
                Text("ChillKey v1.0 • Tối ưu cho Apple Silicon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Đóng") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 480, height: 420)
        .onAppear {
            state.checkPermission()
        }
    }
}
