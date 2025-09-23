import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/branch_provider.dart';
import '../../models/branch.dart';
import '../../widgets/loading_button.dart';

class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  Branch? _selectedBranch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn chi nhánh'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Consumer<BranchProvider>(
        builder: (context, branchProvider, child) {
          if (branchProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (branchProvider.branches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có chi nhánh nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Vui lòng chọn chi nhánh để tiếp tục',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: branchProvider.branches.length,
                    itemBuilder: (context, index) {
                      final branch = branchProvider.branches[index];
                      final isSelected = _selectedBranch?.id == branch.id;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.orange.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.orange : Colors.grey,
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            branch.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.orange : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (branch.addressDetail != null)
                                Text(branch.addressDetail!),
                              if (branch.phone.isNotEmpty)
                                Text('📞 ${branch.phone}'),
                              if (branch.openingHours != null)
                                Text('🕒 ${branch.openingHours}'),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: branch.isActive ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  branch.isActive ? 'Đang hoạt động' : 'Tạm đóng',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.orange,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedBranch = branch;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                LoadingButton(
                  onPressed: _selectedBranch != null
                      ? () {
                          branchProvider.selectBranch(_selectedBranch!);
                        }
                      : null,
                  isLoading: false,
                  text: 'Tiếp tục',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
